@preconcurrency import AVFoundation
import Accelerate
import CoreMedia
import Foundation
import OSLog
import Speech

/// 마이크에서 받은 PCM 오디오를 Apple Speech 프레임워크에 공급하고,
/// `SpeechDetector`의 결과를 앱이 이해하는 발화 시작/종료 이벤트로 변환한다.
///
/// 전체 데이터 흐름은 다음과 같다.
/// `AVAudioEngine input tap` → `AVAudioConverter(Int16 PCM)` → `SpeechAnalyzer`
/// → `SpeechDetector.Result` → `VoiceActivityGate` → coordinator callback.
///
/// `SpeechDetector`만 발화 여부를 판단한다. 아래에서 계산하는 dB 값은 통화 화면의
/// 입력 레벨을 그리기 위한 시각화 데이터일 뿐이며 VAD 판정이나 fallback에 사용하지 않는다.
///
/// 프로젝트가 MainActor 기본 격리를 사용하지만 오디오 tap은 실시간 오디오 스레드에서
/// 호출된다. 이 서비스는 `NSLock`으로 내부 상태를 보호하므로 타입을 `nonisolated`로 두어
/// 오디오 콜백에서 MainActor로 강제 동기 전환되는 문제를 피한다.
nonisolated final class VoiceActivityDetector: @unchecked Sendable {
    private static let logger = Logger(
        subsystem: "com.Team01.Talkie",
        category: "VoiceActivity"
    )

    enum DetectorError: LocalizedError {
        case audioInputUnavailable
        case analyzerAudioFormatUnavailable
        case unsupportedSpeechLocale

        var errorDescription: String? {
            switch self {
            case .audioInputUnavailable:
                "사용할 수 있는 마이크 입력이 없습니다."
            case .analyzerAudioFormatUnavailable:
                "SpeechAnalyzer가 요구하는 16-bit PCM 형식을 준비할 수 없습니다."
            case .unsupportedSpeechLocale:
                "이 기기에서 한국어 SpeechTranscriber 모델을 사용할 수 없습니다."
            }
        }
    }

    // 오디오 서비스는 화면 상태를 직접 알지 않는다. 감지 결과만 callback으로 전달하고,
    // 화면 전환은 MainActor를 소유한 FakeCallCoordinator가 결정한다.
    var onSpeechStarted: (@Sendable () -> Void)?
    var onSpeechEnded: (@Sendable () -> Void)?
    var onDetectionUnavailable: (@Sendable () -> Void)?
    var onInputLevelChanged: (@Sendable (Float) -> Void)?

    // AVAudioEngine의 tap, Speech 결과 Task, UI 요청이 서로 다른 실행 문맥에서 접근하므로
    // 아래 상태는 항상 stateLock 안에서 읽고 쓴다.
    private let audioEngine = AVAudioEngine()
    private let stateLock = NSLock()
    private var gate = VoiceActivityGate()

    private var isRunning = false
    private var isTapInstalled = false
    private var isSpeakerEnabled = false
    private var smoothedInputLevel: Float?
    private var lastPublishedLevelAt: TimeInterval = 0
    // AVAudioEngine의 동기 callback과 SpeechAnalyzer의 비동기 입력을 이어 주는 브리지.
    // 스트림은 최신 버퍼만 제한적으로 보관해 분석이 잠시 느려져도 메모리가 계속 늘지 않는다.
    private var analyzerInputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var analyzerTask: Task<Void, Never>?
    private var detectorResultTask: Task<Void, Never>?
    private var transcriberDrainTask: Task<Void, Never>?
    private var analyzerInputConverter: AVAudioConverter?
    // SpeechDetector 결과의 CMTime은 오디오 스트림 기준이고 gate는 systemUptime을 사용한다.
    // 두 시간축을 처음 결과에서 한 번 맞춘 뒤 같은 offset을 계속 재사용한다.
    private var appleTimelineOffset: TimeInterval?
    // detector와 transcriber 결과 Task가 같은 실패를 각각 보고할 수 있으므로 한 턴에 한 번만 알린다.
    private var hasReportedAppleDetectionFailure = false

    static func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func setSpeakerEnabled(_ enabled: Bool) {
        stateLock.lock()
        isSpeakerEnabled = enabled
        stateLock.unlock()
    }

    func start() throws {
        // 이전 턴의 tap/Task/continuation이 남아 있으면 하나의 마이크 버퍼가 중복 분석된다.
        // 새 감지를 시작하기 전에 항상 이전 파이프라인을 완전히 정리한다.
        stop()

        stateLock.lock()
        let speakerEnabled = isSpeakerEnabled
        stateLock.unlock()
        try FakeCallAudioSession.activate(speakerEnabled: speakerEnabled)

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw DetectorError.audioInputUnavailable
        }

        resetDetectionState(isRunning: true)
        // Speech asset 준비는 비동기일 수 있으므로 analyzer 준비와 마이크 tap 설치를 분리한다.
        // converter가 준비되기 전의 버퍼는 dB 시각화에만 사용되고 발화 이벤트를 만들지 않는다.
        startAppleSpeechDetection(inputFormat: inputFormat)
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1_024,
            format: inputFormat
        ) { [weak self] buffer, _ in
            self?.process(buffer: buffer)
        }
        isTapInstalled = true

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            isTapInstalled = false
            stop()
            throw error
        }
    }

    func stop() {
        // tap을 먼저 제거해 정리 도중 새로운 오디오 버퍼가 process(buffer:)로 들어오지 않게 한다.
        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        stateLock.lock()
        let inputContinuation = analyzerInputContinuation
        let analyzerTask = analyzerTask
        let detectorResultTask = detectorResultTask
        let transcriberDrainTask = transcriberDrainTask
        analyzerInputContinuation = nil
        self.analyzerTask = nil
        self.detectorResultTask = nil
        self.transcriberDrainTask = nil
        analyzerInputConverter = nil
        isRunning = false
        appleTimelineOffset = nil
        hasReportedAppleDetectionFailure = false
        gate.reset()
        stateLock.unlock()

        // lock을 잡은 상태에서 continuation을 종료하거나 Task를 취소하면 종료 callback이
        // 같은 lock을 다시 요구할 수 있다. 참조만 꺼낸 뒤 lock 밖에서 종료한다.
        inputContinuation?.finish()
        analyzerTask?.cancel()
        detectorResultTask?.cancel()
        transcriberDrainTask?.cancel()
    }

    private func process(buffer: AVAudioPCMBuffer) {
        // AVAudioEngine이 route 변경/중단 경계에서 frameLength 또는 byteSize가 0인 버퍼를
        // 전달할 수 있다. 빈 버퍼를 converter에 넣으면 AVAudioBuffer precondition 경고가 난다.
        guard Self.containsAudioData(buffer) else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let decibels = Self.decibels(from: buffer)
        var publishedLevel: Float?
        var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
        var converter: AVAudioConverter?

        stateLock.lock()
        guard isRunning else {
            stateLock.unlock()
            return
        }
        inputContinuation = analyzerInputContinuation
        converter = analyzerInputConverter
        let inputLevel = smoothed(decibels: decibels)
        if now - lastPublishedLevelAt >= 0.1 {
            lastPublishedLevelAt = now
            publishedLevel = inputLevel
        }
        stateLock.unlock()

        // converter가 존재한다는 것은 locale/asset/analyzer 준비가 끝났다는 뜻이다.
        // 아직 준비되지 않았거나 실패한 경우 dB 판정으로 대체하지 않고 입력을 건너뛴다.
        if let converter,
           let analyzerBuffer = try? Self.convert(buffer: buffer, using: converter) {
            inputContinuation?.yield(AnalyzerInput(buffer: analyzerBuffer))
        }
        if let publishedLevel {
            onInputLevelChanged?(publishedLevel)
        }
    }

    private func resetDetectionState(isRunning: Bool) {
        stateLock.lock()
        self.isRunning = isRunning
        appleTimelineOffset = nil
        hasReportedAppleDetectionFailure = false
        gate.reset()
        smoothedInputLevel = nil
        lastPublishedLevelAt = 0
        stateLock.unlock()
    }

    private func startAppleSpeechDetection(inputFormat: AVAudioFormat) {
        // 오디오 callback이 분석 Task보다 빨라질 때 오래된 오디오를 무한히 쌓지 않는다.
        // 100개를 넘으면 가장 오래된 입력 대신 최신 입력을 유지한다.
        let stream = AsyncStream<AnalyzerInput>.makeStream(
            bufferingPolicy: .bufferingNewest(100)
        )
        stateLock.lock()
        analyzerInputContinuation = stream.continuation
        stateLock.unlock()

        analyzerTask = Task { [weak self] in
            do {
                // 한국어와 정확히 같은 식별자가 없을 수도 있어 Apple이 지원하는 동등 locale을 찾는다.
                // 고정 ko_KR을 그대로 module에 넣으면 "unallocated locales" 오류가 발생할 수 있다.
                guard SpeechTranscriber.isAvailable,
                      let locale = await SpeechTranscriber.supportedLocale(
                          equivalentTo: Locale(identifier: "ko_KR")
                      ) else {
                    throw DetectorError.unsupportedSpeechLocale
                }

                // Speech 모듈을 만들기 전에 locale을 예약하고 필요한 온디바이스 asset을 설치한다.
                // 예약 없이 analyzer를 시작하면 현재 할당된 locale이 없다는 precondition을 위반한다.
                try await AssetInventory.reserve(locale: locale)
                // SpeechDetector-only worker는 프레임워크에서 허용되지 않는다.
                // 따라서 transcriber를 필수 동반 module로 넣되 전사 문자열은 앱에서 사용하지 않는다.
                let transcriber = SpeechTranscriber(
                    locale: locale,
                    preset: .transcription
                )
                let detector = SpeechDetector(
                    detectionOptions: .init(sensitivityLevel: .medium),
                    reportResults: true
                )
                let modules: [any SpeechModule] = [detector, transcriber]
                if let request = try await AssetInventory.assetInstallationRequest(
                    supporting: modules
                ) {
                    try await request.downloadAndInstall()
                }

                // SpeechAnalyzer가 선택한 호환 형식을 사용하고, 실제 입력은 반드시 Int16 PCM으로 변환한다.
                // 하드웨어의 Float32 PCM을 그대로 전달하면 "must be 16-bit signed integers"가 발생한다.
                guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
                    compatibleWith: modules,
                    considering: inputFormat
                ), analyzerFormat.commonFormat == .pcmFormatInt16,
                      let converter = AVAudioConverter(
                          from: inputFormat,
                          to: analyzerFormat
                      ) else {
                    throw DetectorError.analyzerAudioFormatUnavailable
                }

                let analyzer = SpeechAnalyzer(modules: modules)
                // 두 결과 sequence는 모두 소비해야 worker가 정상적으로 진행된다.
                // detector 결과는 VAD에 사용하고 transcriber 결과는 의도적으로 폐기한다.
                let detectorResultTask = Task { [weak self, detector] in
                    do {
                        for try await result in detector.results {
                            guard !Task.isCancelled else { return }
                            self?.processAppleDetection(result)
                        }
                    } catch {
                        self?.handleApplePipelineError(error)
                    }
                }
                let transcriberDrainTask = Task { [weak self, transcriber] in
                    do {
                        for try await _ in transcriber.results {
                            guard !Task.isCancelled else { return }
                        }
                    } catch {
                        self?.handleApplePipelineError(error)
                    }
                }

                // asset 다운로드 중 통화가 끝났을 수 있다. 여전히 실행 중일 때만 converter와 Task를 등록한다.
                guard self?.activateApplePipeline(
                    converter: converter,
                    detectorResultTask: detectorResultTask,
                    transcriberDrainTask: transcriberDrainTask
                ) == true else {
                    detectorResultTask.cancel()
                    transcriberDrainTask.cancel()
                    return
                }

                _ = try await analyzer.analyzeSequence(stream.stream)
            } catch {
                self?.handleApplePipelineError(error)
            }
        }
    }

    private func activateApplePipeline(
        converter: AVAudioConverter,
        detectorResultTask: Task<Void, Never>,
        transcriberDrainTask: Task<Void, Never>
    ) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard isRunning else { return false }
        analyzerInputConverter = converter
        self.detectorResultTask = detectorResultTask
        self.transcriberDrainTask = transcriberDrainTask
        return true
    }

    private func processAppleDetection(_ result: SpeechDetector.Result) {
        let rangeStart = CMTimeGetSeconds(result.range.start)
        let rangeEnd = CMTimeGetSeconds(result.range.end)
        var events: [VoiceActivityGate.Event] = []

        stateLock.lock()
        guard isRunning else {
            stateLock.unlock()
            return
        }
        // 정상 결과에는 오디오 구간의 시작/끝이 함께 온다. 같은 Bool 값을 양 끝 시점에 넣어
        // gate가 최소 발화 시간과 연속 무음 시간을 실제 오디오 시간축으로 계산하게 한다.
        if rangeStart.isFinite, rangeEnd.isFinite, rangeEnd >= rangeStart {
            if appleTimelineOffset == nil {
                appleTimelineOffset = ProcessInfo.processInfo.systemUptime - rangeEnd
            }
            let offset = appleTimelineOffset ?? 0
            if let event = gate.process(
                isSpeechDetected: result.speechDetected,
                at: rangeStart + offset
            ) {
                events.append(event)
            }
            if let event = gate.process(
                isSpeechDetected: result.speechDetected,
                at: rangeEnd + offset
            ) {
                events.append(event)
            }
        } else if let event = gate.process(
            // 드물게 range가 유효하지 않으면 현재 uptime을 사용해 감지 자체는 계속 유지한다.
            isSpeechDetected: result.speechDetected,
            at: ProcessInfo.processInfo.systemUptime
        ) {
            events.append(event)
        }
        stateLock.unlock()

        events.forEach(publish)
    }

    private func handleApplePipelineError(_ error: any Error) {
        // stop()이 stream과 결과 Task를 취소할 때 발생하는 CancellationError는 정상 종료다.
        // 이를 분석 실패로 취급하면 통화를 끝낼 때마다 잘못된 fallback 로그가 남는다.
        guard !(error is CancellationError), !Task.isCancelled else { return }

        stateLock.lock()
        guard isRunning, !hasReportedAppleDetectionFailure else {
            stateLock.unlock()
            return
        }
        hasReportedAppleDetectionFailure = true
        analyzerInputConverter = nil
        appleTimelineOffset = nil
        stateLock.unlock()

        // Apple 분석이 실패해도 dB 기반 VAD를 되살리지 않는다. coordinator에 사용 불가 상태를
        // 한 번 알리고, coordinator가 3초 시간 기반 무응답 정책으로 통화를 계속한다.
        Self.logger.error(
            "Apple SpeechDetector 분석 실패: \(String(describing: error), privacy: .public)"
        )
        onDetectionUnavailable?()
    }

    private func publish(_ event: VoiceActivityGate.Event) {
        switch event {
        case .speechStarted:
            onSpeechStarted?()
        case .speechEnded:
            onSpeechEnded?()
        }
    }

    private func smoothed(decibels: Float) -> Float {
        // UI 레벨 막대가 프레임마다 심하게 떨리지 않도록 지수 이동 평균으로 완화한다.
        // 이 값은 SpeechDetector 입력이나 발화 판정에 사용되지 않는다.
        let clamped = min(max(decibels, -80), 0)
        guard let previous = smoothedInputLevel else {
            smoothedInputLevel = clamped
            return clamped
        }
        let next = previous + 0.3 * (clamped - previous)
        smoothedInputLevel = next
        return next
    }

    private static func decibels(from buffer: AVAudioPCMBuffer) -> Float {
        // 첫 채널의 RMS를 사람이 읽기 쉬운 dBFS 값으로 변환한다. log10(0)을 피하기 위해
        // 아주 작은 하한을 두며, 결과는 오직 입력 레벨 시각화에만 전달한다.
        guard let channelData = buffer.floatChannelData?.pointee else { return -160 }
        let frameCount = vDSP_Length(buffer.frameLength)
        guard frameCount > 0 else { return -160 }
        var meanSquare: Float = 0
        vDSP_measqv(channelData, 1, &meanSquare, frameCount)
        return 20 * log10(max(sqrt(meanSquare), 0.000_000_1))
    }

    private static func containsAudioData(_ buffer: AVAudioPCMBuffer) -> Bool {
        guard buffer.frameLength > 0 else { return false }
        let buffers = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
        return !buffers.isEmpty && buffers.allSatisfy {
            $0.mData != nil && $0.mDataByteSize > 0
        }
    }

    private static func convert(
        buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter
    ) throws -> AVAudioPCMBuffer {
        // sample rate가 달라질 수 있으므로 입력 frame 수를 그대로 capacity로 쓰지 않는다.
        // 변환 비율과 작은 여유분을 반영해 출력 버퍼 부족을 방지한다.
        let ratio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
        let capacity = AVAudioFrameCount(ceil(Double(buffer.frameLength) * ratio)) + 32
        guard let output = AVAudioPCMBuffer(
            pcmFormat: converter.outputFormat,
            frameCapacity: capacity
        ) else {
            throw DetectorError.analyzerAudioFormatUnavailable
        }

        // 이 호출에서는 하나의 input buffer만 공급한다. converter가 추가 입력을 요청하면
        // noDataNow로 응답해 같은 버퍼가 중복 소비되지 않게 한다.
        var suppliedInput = false
        var conversionError: NSError?
        let status = converter.convert(to: output, error: &conversionError) { _, status in
            guard !suppliedInput else {
                status.pointee = .noDataNow
                return nil
            }
            suppliedInput = true
            status.pointee = .haveData
            return buffer
        }
        if let conversionError { throw conversionError }
        // 변환 API가 성공을 반환해도 frameLength/byteSize가 0일 수 있으므로 실제 PCM 데이터까지 확인한다.
        guard status == .haveData || status == .inputRanDry,
              output.format.commonFormat == .pcmFormatInt16,
              containsAudioData(output) else {
            throw DetectorError.analyzerAudioFormatUnavailable
        }
        return output
    }
}

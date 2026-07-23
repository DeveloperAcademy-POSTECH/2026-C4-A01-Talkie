//
//  FakeCallCoordinator.swift
//  Talkie
//


@preconcurrency import AVFoundation
import Foundation
import Observation

/// NotificationCenter observer의 등록과 해제를 MainActor 상태에서 분리합니다.
/// Coordinator가 사라질 때 이 객체의 deinit이 토큰을 정리하므로 고아 observer가 남지 않습니다.
nonisolated private final class FakeCallAudioInterruptionObserver: @unchecked Sendable {
    private var token: NSObjectProtocol?

    init(onShouldResume: @escaping @Sendable () -> Void) {
        token = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { notification in
            guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: rawType) == .ended else {
                return
            }

            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let shouldResume = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
                .contains(.shouldResume)
            guard shouldResume else { return }
            onShouldResume()
        }
    }

    deinit {
        if let token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}

enum FakeCallPhase: Equatable {
    case idle
    case loading
    case incoming
    case playingLine(Int)
    case waitingForUser
    case userSpeaking
    case waitingForNextLine
    case completed
    case failed(String)

    var isActiveCall: Bool {
        switch self {
        case .playingLine, .waitingForUser, .userSpeaking, .waitingForNextLine, .completed:
            true
        case .idle, .loading, .incoming, .failed:
            false
        }
    }

}

enum VoiceMonitoringState: Equatable {
    case inactive
    case listening
    case speechDetected
    case unavailable
}

/// Coordinator가 오디오 엔진을 정리한 뒤 저장 계층으로 넘기는 통화 완료 값입니다.
/// SwiftData 모델을 직접 소유하지 않아 오디오 상태 머신과 저장 컨텍스트를 분리합니다.
struct CompletedFakeCallSession: Sendable {
    let startedAt: Date
    let endedAt: Date
    let scenarioTitle: String
    let callerName: String
    let endReason: CallEndReason
    let recording: CompletedCallRecording?
}

@MainActor
@Observable
/// 가상 통화 화면의 상태와 재생/VAD 수명주기를 한 곳에서 조정한다.
/// 적응형 VAD의 callback은 오디오 실행 문맥에서 오므로 `bindVoiceActivityEvents()`에서
/// MainActor로 되돌린 뒤에만 phase와 SwiftUI 관찰 상태를 변경한다.
final class FakeCallCoordinator {
    private(set) var phase: FakeCallPhase = .idle
    private(set) var profile: VirtualCallerProfile?
    private(set) var scriptLines: [FakeCallScriptLine] = []
    private(set) var currentLineIndex = 0
    private(set) var callStartedAt: Date?
    private(set) var currentInputLevel = -80.0
    private(set) var voiceMonitoringState: VoiceMonitoringState = .inactive
    private(set) var isSpeakerEnabled = false

    private var repository: any FakeCallScriptRepository
    private let audioPlayer: ScriptedAudioPlayer
    private let voiceActivityDetector: VoiceActivityDetector
    private let audioCaptureService: CallAudioCaptureService
    private let ringtonePlayer: any IncomingCallRingtonePlaying
    private let proximityMonitor: CallProximityMonitor

    private var hasMicrophonePermission = false
    private var activeScenarioTitle = "가상 통화"
    private var playbackPreparationTask: Task<Void, Never>?
    private var audioInterruptionObserver: FakeCallAudioInterruptionObserver?
    /// 오디오 callback이 MainActor에 도착하기 전에 다음 턴이 시작돼도 이전 결과를 무시하기 위한 식별자입니다.
    private var activeVoiceTurnID: UUID?

    init(repository: (any FakeCallScriptRepository)? = nil) {
        let voiceActivityDetector = VoiceActivityDetector()
        self.repository = repository ?? MockFakeCallScriptRepository()
        audioPlayer = ScriptedAudioPlayer()
        self.voiceActivityDetector = voiceActivityDetector
        audioCaptureService = CallAudioCaptureService(
            voiceActivityDetector: voiceActivityDetector
        )
        ringtonePlayer = IncomingCallRingtoneService.shared
        proximityMonitor = CallProximityMonitor()
        bindVoiceActivityEvents()
        observeAudioSessionInterruption()
    }

    init(
        repository: any FakeCallScriptRepository,
        audioPlayer: ScriptedAudioPlayer,
        voiceActivityDetector: VoiceActivityDetector,
        ringtonePlayer: (any IncomingCallRingtonePlaying)? = nil,
        proximityMonitor: CallProximityMonitor? = nil
    ) {
        self.repository = repository
        self.audioPlayer = audioPlayer
        self.voiceActivityDetector = voiceActivityDetector
        audioCaptureService = CallAudioCaptureService(
            voiceActivityDetector: voiceActivityDetector
        )
        self.ringtonePlayer = ringtonePlayer ?? IncomingCallRingtoneService.shared
        self.proximityMonitor = proximityMonitor ?? CallProximityMonitor()
        bindVoiceActivityEvents()
        observeAudioSessionInterruption()
    }

    func startIncomingCall() {
        resetRuntimeState()
        phase = .loading

        Task {
            do {
                let loadedProfile = try await repository.activeProfile()
                let loadedLines = try await repository.scriptLines(for: loadedProfile.id)

                guard !loadedLines.isEmpty else {
                    phase = .failed("재생할 가상 통화 문장이 없습니다.")
                    return
                }

                await ringtonePlayer.prepareForRinging()
                guard !Task.isCancelled else { return }

                profile = loadedProfile
                scriptLines = loadedLines
                phase = .incoming
                await ringtonePlayer.startRinging(callerName: loadedProfile.displayName)

                if phase != .incoming {
                    ringtonePlayer.stopRinging()
                }
            } catch {
                phase = .failed("가상 통화를 준비하지 못했습니다.")
            }
        }
    }

    /// Keeps the coordinator identity stable for SwiftUI while replacing only
    /// the scenario data source used by the next call session.
    func startIncomingCall(repository: any FakeCallScriptRepository) {
        self.repository = repository
        startIncomingCall()
    }

    func acceptCall(recordsAudio: Bool, scenarioTitle: String) {
        guard phase == .incoming else { return }

        ringtonePlayer.stopRinging()
        callStartedAt = Date()
        activeScenarioTitle = scenarioTitle
        proximityMonitor.update(
            isCallActive: true,
            isSpeakerEnabled: isSpeakerEnabled
        )

        Task {
            hasMicrophonePermission = await VoiceActivityDetector.requestPermission()
            if hasMicrophonePermission {
                do {
                    try audioCaptureService.start(
                        speakerEnabled: isSpeakerEnabled,
                        recordsAudio: recordsAudio
                    )
                    voiceMonitoringState = .inactive
                } catch {
                    hasMicrophonePermission = false
                    voiceMonitoringState = .unavailable
                }
            } else {
                voiceMonitoringState = .unavailable
            }
            playCurrentLine()
        }
    }

    func declineCall() {
        _ = endCall()
    }

    @discardableResult
    func endCall(reason requestedReason: CallEndReason = .userEnded) -> CompletedFakeCallSession? {
        let startedAt = callStartedAt
        let callerName = profile?.displayName
        let scenarioTitle = activeScenarioTitle
        let endReason: CallEndReason = phase == .completed ? .completed : requestedReason

        cancelPendingWork()
        audioPlayer.stop()
        stopVoiceMonitoring()
        let recording = audioCaptureService.finish()
        FakeCallAudioSession.deactivate()
        resetRuntimeState()
        phase = .idle

        guard let startedAt, let callerName else { return nil }
        return CompletedFakeCallSession(
            startedAt: startedAt,
            endedAt: Date(),
            scenarioTitle: scenarioTitle,
            callerName: callerName,
            endReason: endReason,
            recording: recording
        )
    }

    func skipToNextLine() {
        guard phase.isActiveCall else { return }
        advanceAfterUserTurn()
    }

    func setSpeakerEnabled(_ enabled: Bool) {
        do {
            try FakeCallAudioSession.setSpeakerEnabled(enabled)
            isSpeakerEnabled = enabled
            proximityMonitor.update(
                isCallActive: phase.isActiveCall,
                isSpeakerEnabled: enabled
            )
        } catch {
            return
        }
    }

    /// 홈 화면 이동, 화면 잠금, 다른 앱 전환처럼 프로세스가 살아 있는 백그라운드 상태에서
    /// 통화 오디오와 마이크 입력을 계속 유지합니다. 정상 실행 중이면 아무것도 재생성하지 않습니다.
    func resumeAudioIfNeeded() {
        guard phase.isActiveCall else { return }

        audioPlayer.resumeIfNeeded(speakerEnabled: isSpeakerEnabled)

        guard hasMicrophonePermission else { return }
        do {
            try audioCaptureService.resumeIfNeeded(
                speakerEnabled: isSpeakerEnabled
            )
        } catch {
            hasMicrophonePermission = false
            voiceMonitoringState = .unavailable
            activeVoiceTurnID = nil
        }
    }

    private func playCurrentLine() {
        // 상대방 음성이 마이크로 다시 들어가 사용자 발화로 오인되지 않도록 재생 중에는 VAD를 멈춘다.
        cancelPendingWork()
        stopVoiceMonitoring()

        guard scriptLines.indices.contains(currentLineIndex) else {
            phase = .completed
            return
        }

        phase = .playingLine(currentLineIndex)
        let line = scriptLines[currentLineIndex]

        playbackPreparationTask = Task { [weak self] in
            guard let self else { return }

            do {
                let clip = try await repository.voiceClip(for: line.id)
                guard !Task.isCancelled,
                      scriptLines.indices.contains(currentLineIndex),
                      scriptLines[currentLineIndex].id == line.id else {
                    return
                }

                // 상대방 음원이 스피커로 나오기 전에만 초기 환경 소음 보정을 허용합니다.
                audioCaptureService.endAmbientCalibration()
                audioPlayer.play(
                    text: line.text,
                    audioFileURL: audioFileURL(for: clip),
                    speakerEnabled: isSpeakerEnabled
                ) { [weak self] in
                    self?.waitForUserSpeech()
                }
            } catch {
                guard !Task.isCancelled else { return }
                phase = .failed("시나리오 음원을 불러오지 못했습니다.")
            }
        }
    }

    private func waitForUserSpeech() {
        // 상대 문장 재생이 끝나면 적응형 VAD가 오디오 버퍼 시간으로 연속 무음을 측정합니다.
        // 별도 Task.sleep 타이머가 없으므로 소리가 들어온 동안 3초가 벽시계처럼 흐르지 않습니다.
        phase = .waitingForUser
        currentInputLevel = -80

        if hasMicrophonePermission {
            do {
                voiceMonitoringState = .listening
                activeVoiceTurnID = try audioCaptureService.beginVoiceDetection()
            } catch {
                hasMicrophonePermission = false
                voiceMonitoringState = .unavailable
                activeVoiceTurnID = nil
            }
        } else {
            voiceMonitoringState = .unavailable
            activeVoiceTurnID = nil
        }
    }

    private func handleSpeechStarted(turnID: UUID) {
        guard phase == .waitingForUser, activeVoiceTurnID == turnID else { return }
        voiceMonitoringState = .speechDetected
        phase = .userSpeaking
    }

    private func handleSpeechEnded(turnID: UUID) {
        guard phase == .userSpeaking, activeVoiceTurnID == turnID else { return }

        // Gate가 이미 연속 무음을 확인했으므로 입력을 정리하고 즉시 다음 문장으로 진행한다.
        stopVoiceMonitoring()
        phase = .waitingForNextLine
        advanceAfterUserTurn()
    }

    private func handleContinuousSilenceReached(turnID: UUID) {
        guard phase == .waitingForUser, activeVoiceTurnID == turnID else { return }
        // VAD가 실제 입력 버퍼에서 3초의 연속 무음을 확인한 경우에만 다음 문장으로 진행합니다.
        advanceAfterUserTurn()
    }

    private func advanceAfterUserTurn() {
        cancelPendingWork()
        stopVoiceMonitoring()

        let nextIndex = currentLineIndex + 1
        guard scriptLines.indices.contains(nextIndex) else {
            phase = .completed
            return
        }

        currentLineIndex = nextIndex
        playCurrentLine()
    }

    private func bindVoiceActivityEvents() {
        // VoiceActivityDetector는 nonisolated 서비스다. 모든 UI 상태 변경은 명시적으로 MainActor에서 수행한다.
        voiceActivityDetector.onSpeechStarted = { [weak self] turnID in
            guard let coordinator = self else { return }
            Task { @MainActor in
                coordinator.handleSpeechStarted(turnID: turnID)
            }
        }

        voiceActivityDetector.onSpeechEnded = { [weak self] turnID in
            guard let coordinator = self else { return }
            Task { @MainActor in
                coordinator.handleSpeechEnded(turnID: turnID)
            }
        }

        voiceActivityDetector.onContinuousSilenceReached = { [weak self] turnID in
            guard let coordinator = self else { return }
            Task { @MainActor in
                coordinator.handleContinuousSilenceReached(turnID: turnID)
            }
        }

        voiceActivityDetector.onInputLevelChanged = { [weak self] level in
            guard let coordinator = self else { return }
            Task { @MainActor in
                guard coordinator.voiceMonitoringState == .listening
                        || coordinator.voiceMonitoringState == .speechDetected else {
                    return
                }

                // 입력 dB는 화면 레벨 표시 전용이다. 이 값을 사용해 phase를 바꾸거나 발화를 판정하지 않는다.
                coordinator.currentInputLevel = Double(
                    min(max(level, -80), 0)
                )
            }
        }
    }

    /// 일반 전화나 Siri 등으로 오디오 session이 중단됐다가 시스템이 재개를 허용하면
    /// 백그라운드 여부와 관계없이 기존 통화의 재생기와 마이크 엔진을 복구합니다.
    private func observeAudioSessionInterruption() {
        audioInterruptionObserver = FakeCallAudioInterruptionObserver { [weak self] in
            Task { @MainActor [weak self] in
                self?.resumeAudioIfNeeded()
            }
        }
    }

    private func cancelPendingWork() {
        playbackPreparationTask?.cancel()
        playbackPreparationTask = nil
    }

    private func stopVoiceMonitoring() {
        audioCaptureService.stopVoiceDetection()
        activeVoiceTurnID = nil
        currentInputLevel = -80
        voiceMonitoringState = hasMicrophonePermission ? .inactive : .unavailable
    }

    private func audioFileURL(for metadata: VoiceClipMetadata?) -> URL? {
        guard let fileName = metadata?.localFileName,
              !fileName.isEmpty else {
            return nil
        }

        let fileManager = FileManager.default
        let directURL = URL(fileURLWithPath: fileName)

        if directURL.isFileURL,
           directURL.path.hasPrefix("/"),
           fileManager.fileExists(atPath: directURL.path) {
            return directURL
        }

        var candidates: [URL] = []

        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(resourceURL.appendingPathComponent(fileName))
            candidates.append(resourceURL.appendingPathComponent(directURL.lastPathComponent))
        }

        if let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first {
            candidates.append(
                documentsURL
                    .appendingPathComponent("VoiceClips", isDirectory: true)
                    .appendingPathComponent(fileName)
            )
        }

        if let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            candidates.append(
                applicationSupportURL
                    .appendingPathComponent("VoiceClips", isDirectory: true)
                    .appendingPathComponent(fileName)
            )
        }

        return candidates.first { fileManager.fileExists(atPath: $0.path) }
    }

    private func resetRuntimeState() {
        cancelPendingWork()
        ringtonePlayer.stopRinging()
        proximityMonitor.stop()
        currentLineIndex = 0
        callStartedAt = nil
        hasMicrophonePermission = false
        activeScenarioTitle = "가상 통화"
        currentInputLevel = -80
        voiceMonitoringState = .inactive
        isSpeakerEnabled = false
        profile = nil
        scriptLines = []
    }
}

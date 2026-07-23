@preconcurrency import AVFoundation
import Accelerate
import Foundation

/// CallAudioCaptureService의 단일 마이크 tap에서 받은 PCM을 적응형 VAD 이벤트로 바꿉니다.
///
/// 이전 구현의 SpeechAnalyzer / SpeechTranscriber / SpeechDetector는 전사 모델과 locale asset을
/// 필요로 했지만, 가상 통화에 필요한 값은 발화 시작과 종료뿐입니다. 이 구현은 PCM의 RMS를
/// dBFS로 바꾼 뒤 `VoiceActivityGate`가 학습한 주변 소음과 비교합니다.
///
/// 오디오 tap은 실시간 오디오 스레드에서 호출되므로 MainActor로 강제 이동하지 않습니다.
/// 내부 상태는 `NSLock`으로 보호하고, 화면 상태 변경은 callback을 받은 coordinator가 MainActor에서
/// 수행합니다.
nonisolated final class VoiceActivityDetector: @unchecked Sendable {
    var onSpeechStarted: (@Sendable (UUID) -> Void)?
    var onSpeechEnded: (@Sendable (UUID) -> Void)?
    var onContinuousSilenceReached: (@Sendable (UUID) -> Void)?
    var onInputLevelChanged: (@Sendable (Float) -> Void)?

    private let stateLock = NSLock()
    private var gate = VoiceActivityGate()
    private var activeTurnID: UUID?
    private var isAmbientCalibrationEnabled = false
    private var smoothedInputLevel: Float?
    private var lastPublishedLevelAt: TimeInterval = 0

    static func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    /// 마이크 엔진이 켜진 뒤 상대방 음원이 재생되기 전까지만 주변 소음 기준을 빠르게 준비합니다.
    func beginAmbientCalibration() {
        stateLock.lock()
        isAmbientCalibrationEnabled = true
        stateLock.unlock()
    }

    /// 앱의 상대방 음성이 마이크로 유입되어 주변 소음 기준을 오염시키지 않게 보정을 닫습니다.
    func endAmbientCalibration() {
        stateLock.lock()
        isAmbientCalibrationEnabled = false
        stateLock.unlock()
    }

    /// 새 사용자 턴을 열고, 늦게 도착한 이전 턴 callback을 구분할 UUID를 반환합니다.
    /// 통화 중 학습된 주변 소음값은 유지하므로 매 문장마다 다시 보정하지 않습니다.
    func beginListening() -> UUID {
        let turnID = UUID()
        stateLock.lock()
        gate.resetTurn()
        activeTurnID = turnID
        isAmbientCalibrationEnabled = false
        smoothedInputLevel = nil
        lastPublishedLevelAt = 0
        stateLock.unlock()
        return turnID
    }

    /// 상대방 음원 재생 중에는 이벤트 발행을 멈추되, 마이크 tap 자체와 녹음은 유지합니다.
    func pauseListening() {
        stateLock.lock()
        activeTurnID = nil
        gate.resetTurn()
        smoothedInputLevel = nil
        lastPublishedLevelAt = 0
        stateLock.unlock()
    }

    /// 통화가 끝날 때 학습된 소음값까지 폐기합니다.
    func reset() {
        stateLock.lock()
        activeTurnID = nil
        isAmbientCalibrationEnabled = false
        gate.resetAll()
        smoothedInputLevel = nil
        lastPublishedLevelAt = 0
        stateLock.unlock()
    }

    /// 단일 input tap이 전달한 버퍼를 녹음과 독립적으로 분석합니다.
    /// route 변경 경계에서 들어오는 0-byte 버퍼는 AVAudioBuffer 경고를 피하기 위해 무시합니다.
    func process(buffer: AVAudioPCMBuffer) {
        guard Self.containsAudioData(buffer), buffer.format.sampleRate > 0 else { return }

        let levelDBFS = Self.decibels(from: buffer)
        let duration = Double(buffer.frameLength) / buffer.format.sampleRate
        let now = ProcessInfo.processInfo.systemUptime
        var event: VoiceActivityGate.Event?
        var eventTurnID: UUID?
        var publishedLevel: Float?

        stateLock.lock()
        if let turnID = activeTurnID {
            event = gate.process(levelDBFS: levelDBFS, duration: duration)
            eventTurnID = turnID

            let inputLevel = smoothed(decibels: levelDBFS)
            if now - lastPublishedLevelAt >= 0.1 {
                lastPublishedLevelAt = now
                publishedLevel = inputLevel
            }
        } else if isAmbientCalibrationEnabled {
            // 상대방 음원 재생 직전의 제한된 구간에서만 실제 환경 소음 기준을 준비합니다.
            gate.observeAmbient(levelDBFS: levelDBFS)
        }
        stateLock.unlock()

        if let event, let eventTurnID {
            publish(event, turnID: eventTurnID)
        }
        if let publishedLevel {
            onInputLevelChanged?(publishedLevel)
        }
    }

    private func publish(_ event: VoiceActivityGate.Event, turnID: UUID) {
        switch event {
        case .speechStarted:
            onSpeechStarted?(turnID)
        case .speechEnded:
            onSpeechEnded?(turnID)
        case .continuousSilenceReached:
            onContinuousSilenceReached?(turnID)
        }
    }

    private func smoothed(decibels: Float) -> Float {
        // UI 레벨 막대만 완화합니다. VAD 상태 기계에는 원래의 dBFS와 버퍼 시간이 전달됩니다.
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
        guard let channelData = buffer.floatChannelData?.pointee else { return -80 }
        let frameCount = vDSP_Length(buffer.frameLength)
        guard frameCount > 0 else { return -80 }

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
}

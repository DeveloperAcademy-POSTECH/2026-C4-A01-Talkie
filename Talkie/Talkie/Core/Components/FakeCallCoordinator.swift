//
//  FakeCallCoordinator.swift
//  Talkie
//


import Foundation
import Observation

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
/// SpeechDetector 서비스의 callback은 임의 실행 문맥에서 오므로 `bindVoiceActivityEvents()`에서
/// MainActor로 되돌린 뒤에만 phase와 SwiftUI 관찰 상태를 변경한다.
final class FakeCallCoordinator {
    // SpeechDetector가 결과를 내지 못하거나 사용자가 말하지 않아도 통화가 멈추지 않게 하는 시간 정책.
    // 이것은 발화 판정 대체 알고리즘이 아니라, VAD와 독립된 진행 안전장치다.
    static let noSpeechFallbackDelay: Duration = .seconds(3)

    private(set) var phase: FakeCallPhase = .idle
    private(set) var profile: VirtualCallerProfile?
    private(set) var scriptLines: [FakeCallScriptLine] = []
    private(set) var currentLineIndex = 0
    private(set) var callStartedAt: Date?
    private(set) var currentInputLevel = -80.0
    private(set) var voiceMonitoringState: VoiceMonitoringState = .inactive
    private(set) var isSpeakerEnabled = false

    private let repository: any FakeCallScriptRepository
    private let audioPlayer: ScriptedAudioPlayer
    private let voiceActivityDetector: VoiceActivityDetector
    private let audioCaptureService: CallAudioCaptureService
    private let ringtonePlayer: any IncomingCallRingtonePlaying

    private var hasMicrophonePermission = false
    private var activeScenarioTitle = "가상 통화"
    private var playbackPreparationTask: Task<Void, Never>?
    private var fallbackTask: Task<Void, Never>?

    init(repository: (any FakeCallScriptRepository)? = nil) {
        let voiceActivityDetector = VoiceActivityDetector()
        self.repository = repository ?? MockFakeCallScriptRepository()
        audioPlayer = ScriptedAudioPlayer()
        self.voiceActivityDetector = voiceActivityDetector
        audioCaptureService = CallAudioCaptureService(
            voiceActivityDetector: voiceActivityDetector
        )
        ringtonePlayer = IncomingCallRingtoneService.shared
        bindVoiceActivityEvents()
    }

    init(
        repository: any FakeCallScriptRepository,
        audioPlayer: ScriptedAudioPlayer,
        voiceActivityDetector: VoiceActivityDetector,
        ringtonePlayer: (any IncomingCallRingtonePlaying)? = nil
    ) {
        self.repository = repository
        self.audioPlayer = audioPlayer
        self.voiceActivityDetector = voiceActivityDetector
        audioCaptureService = CallAudioCaptureService(
            voiceActivityDetector: voiceActivityDetector
        )
        self.ringtonePlayer = ringtonePlayer ?? IncomingCallRingtoneService.shared
        bindVoiceActivityEvents()
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

    func acceptCall(recordsAudio: Bool, scenarioTitle: String) {
        guard phase == .incoming else { return }

        ringtonePlayer.stopRinging()
        callStartedAt = Date()
        activeScenarioTitle = scenarioTitle

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
        } catch {
            return
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

            let clip = try? await repository.voiceClip(for: line.id)
            guard !Task.isCancelled,
                  scriptLines.indices.contains(currentLineIndex),
                  scriptLines[currentLineIndex].id == line.id else {
                return
            }

            audioPlayer.play(
                text: line.text,
                audioFileURL: audioFileURL(for: clip),
                speakerEnabled: isSpeakerEnabled
            ) { [weak self] in
                self?.waitForUserSpeech()
            }
        }
    }

    private func waitForUserSpeech() {
        // 상대 문장 재생이 끝난 시점부터 마이크 분석과 3초 무응답 타이머를 동시에 시작한다.
        phase = .waitingForUser
        currentInputLevel = -80

        if hasMicrophonePermission {
            do {
                voiceMonitoringState = .listening
                try audioCaptureService.startVoiceDetection()
            } catch {
                hasMicrophonePermission = false
                voiceMonitoringState = .unavailable
            }
        } else {
            voiceMonitoringState = .unavailable
        }

        scheduleNoSpeechFallback()
    }

    private func handleSpeechStarted() {
        guard phase == .waitingForUser else { return }
        // 실제 발화가 시작됐으므로 무응답 타이머가 문장 중간에 다음 턴으로 넘기지 않게 취소한다.
        fallbackTask?.cancel()
        fallbackTask = nil
        voiceMonitoringState = .speechDetected
        phase = .userSpeaking
    }

    private func handleSpeechEnded() {
        guard phase == .userSpeaking else { return }

        // Gate가 이미 연속 무음을 확인했으므로 입력을 정리하고 즉시 다음 문장으로 진행한다.
        stopVoiceMonitoring()
        phase = .waitingForNextLine
        advanceAfterUserTurn()
    }

    private func handleDetectionUnavailable() {
        guard phase == .waitingForUser || phase == .userSpeaking else { return }
        audioCaptureService.stopVoiceDetection()
        voiceMonitoringState = .unavailable
        currentInputLevel = -80
        phase = .waitingForUser
        // Apple 파이프라인이 중간에 실패했을 때도 dB 판정으로 전환하지 않는다.
        // 이미 speechStarted를 받은 뒤 실패한 경우까지 waitingForUser로 되돌려 3초 후 안전하게 진행한다.
        scheduleNoSpeechFallback()
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

    private func scheduleNoSpeechFallback() {
        // 호출될 때마다 이전 Task를 취소해 한 턴에 여러 타이머가 경쟁하지 않게 한다.
        fallbackTask?.cancel()
        fallbackTask = Task { [weak self] in
            try? await Task.sleep(for: Self.noSpeechFallbackDelay)
            guard !Task.isCancelled else { return }
            self?.advanceAfterUserTurn()
        }
    }

    private func bindVoiceActivityEvents() {
        // VoiceActivityDetector는 nonisolated 서비스다. 모든 UI 상태 변경은 명시적으로 MainActor에서 수행한다.
        voiceActivityDetector.onSpeechStarted = { [weak self] in
            guard let coordinator = self else { return }
            Task { @MainActor in
                coordinator.handleSpeechStarted()
            }
        }

        voiceActivityDetector.onSpeechEnded = { [weak self] in
            guard let coordinator = self else { return }
            Task { @MainActor in
                coordinator.handleSpeechEnded()
            }
        }

        voiceActivityDetector.onDetectionUnavailable = { [weak self] in
            guard let coordinator = self else { return }
            Task { @MainActor in
                coordinator.handleDetectionUnavailable()
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

    private func cancelPendingWork() {
        playbackPreparationTask?.cancel()
        playbackPreparationTask = nil
        fallbackTask?.cancel()
        fallbackTask = nil
    }

    private func stopVoiceMonitoring() {
        audioCaptureService.stopVoiceDetection()
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

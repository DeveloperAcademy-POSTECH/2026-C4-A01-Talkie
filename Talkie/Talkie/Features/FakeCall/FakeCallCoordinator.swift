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

@MainActor
@Observable
final class FakeCallCoordinator {
    static let speechThresholdRange = Double(VoiceActivityDetector.speechThresholdRange.lowerBound)
        ... Double(VoiceActivityDetector.speechThresholdRange.upperBound)

    private(set) var phase: FakeCallPhase = .idle
    private(set) var profile: VirtualCallerProfile?
    private(set) var scriptLines: [FakeCallScriptLine] = []
    private(set) var currentLineIndex = 0
    private(set) var callStartedAt: Date?
    private(set) var speechThreshold: Double
    private(set) var isSpeakerEnabled = false

    private let repository: any FakeCallScriptRepository
    private let audioPlayer: ScriptedAudioPlayer
    private let voiceActivityDetector: VoiceActivityDetector
    private let ringtonePlayer: any IncomingCallRingtonePlaying

    private var hasMicrophonePermission = false
    private var playbackPreparationTask: Task<Void, Never>?
    private var fallbackTask: Task<Void, Never>?
    private var nextLineTask: Task<Void, Never>?

    init(repository: (any FakeCallScriptRepository)? = nil) {
        let voiceActivityDetector = VoiceActivityDetector()
        self.repository = repository ?? MockFakeCallScriptRepository()
        audioPlayer = ScriptedAudioPlayer()
        self.voiceActivityDetector = voiceActivityDetector
        ringtonePlayer = IncomingCallRingtoneService.shared
        speechThreshold = Double(voiceActivityDetector.speechThreshold)
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
        self.ringtonePlayer = ringtonePlayer ?? IncomingCallRingtoneService.shared
        speechThreshold = Double(voiceActivityDetector.speechThreshold)
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

    func acceptCall() {
        guard phase == .incoming else { return }

        ringtonePlayer.stopRinging()
        callStartedAt = Date()

        Task {
            hasMicrophonePermission = await VoiceActivityDetector.requestPermission()
            playCurrentLine()
        }
    }

    func declineCall() {
        endCall()
    }

    func endCall() {
        cancelPendingWork()
        audioPlayer.stop()
        voiceActivityDetector.stop()
        FakeCallAudioSession.deactivate()
        resetRuntimeState()
        phase = .idle
    }

    func skipToNextLine() {
        guard phase.isActiveCall else { return }
        advanceAfterUserTurn()
    }

    func updateSpeechThreshold(_ threshold: Double) {
        let clampedThreshold = min(
            max(threshold, Self.speechThresholdRange.lowerBound),
            Self.speechThresholdRange.upperBound
        )
        voiceActivityDetector.updateSpeechThreshold(Float(clampedThreshold))
        speechThreshold = clampedThreshold
    }

    func setSpeakerEnabled(_ enabled: Bool) {
        do {
            try FakeCallAudioSession.setSpeakerEnabled(enabled)
            voiceActivityDetector.setSpeakerEnabled(enabled)
            isSpeakerEnabled = enabled
        } catch {
            return
        }
    }

    private func playCurrentLine() {
        cancelPendingWork()
        voiceActivityDetector.stop()

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
        phase = .waitingForUser

        if hasMicrophonePermission {
            do {
                try voiceActivityDetector.start()
            } catch {
                hasMicrophonePermission = false
            }
        }

        scheduleNoSpeechFallback()
    }

    private func handleSpeechStarted() {
        guard phase == .waitingForUser else { return }
        fallbackTask?.cancel()
        fallbackTask = nil
        phase = .userSpeaking
    }

    private func handleSpeechEnded() {
        guard phase == .userSpeaking else { return }

        voiceActivityDetector.stop()
        phase = .waitingForNextLine

        nextLineTask?.cancel()
        nextLineTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            self?.advanceAfterUserTurn()
        }
    }

    private func advanceAfterUserTurn() {
        cancelPendingWork()
        voiceActivityDetector.stop()

        let nextIndex = currentLineIndex + 1
        guard scriptLines.indices.contains(nextIndex) else {
            phase = .completed
            return
        }

        currentLineIndex = nextIndex
        playCurrentLine()
    }

    private func scheduleNoSpeechFallback() {
        fallbackTask?.cancel()
        fallbackTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            self?.advanceAfterUserTurn()
        }
    }

    private func bindVoiceActivityEvents() {
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
    }

    private func cancelPendingWork() {
        playbackPreparationTask?.cancel()
        playbackPreparationTask = nil
        fallbackTask?.cancel()
        fallbackTask = nil
        nextLineTask?.cancel()
        nextLineTask = nil
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
        isSpeakerEnabled = false
        voiceActivityDetector.setSpeakerEnabled(false)
        profile = nil
        scriptLines = []
    }
}

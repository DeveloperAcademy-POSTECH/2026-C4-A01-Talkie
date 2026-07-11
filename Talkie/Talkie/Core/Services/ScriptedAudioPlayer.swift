//
//  ScriptedAudioPlayer.swift
//  Talkie
//


@preconcurrency import AVFoundation

enum FakeCallAudioSession {
    static func activate(speakerEnabled: Bool) throws {
        let session = AVAudioSession.sharedInstance()
        try configureAndActivate(session)
        try applyOutputRoute(speakerEnabled: speakerEnabled, to: session)
    }

    static func setSpeakerEnabled(_ enabled: Bool) throws {
        let session = AVAudioSession.sharedInstance()
        try configureAndActivate(session)
        try applyOutputRoute(speakerEnabled: enabled, to: session)
    }

    static func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    private static func configureAndActivate(_ session: AVAudioSession) throws {
        let desiredOptions: AVAudioSession.CategoryOptions = [.allowBluetoothHFP]

        if session.category != .playAndRecord
            || session.mode != .voiceChat
            || session.categoryOptions != desiredOptions {
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: desiredOptions
            )
        }

        try session.setActive(true)
    }

    private static func applyOutputRoute(
        speakerEnabled: Bool,
        to session: AVAudioSession
    ) throws {
        try session.overrideOutputAudioPort(
            speakerEnabled ? .speaker : .none
        )
    }
}

@MainActor
final class ScriptedAudioPlayer: NSObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var filePlayer: AVAudioPlayer?
    private var completion: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func play(
        text: String,
        audioFileURL: URL?,
        speakerEnabled: Bool,
        completion: @escaping () -> Void
    ) {
        stop()

        do {
            try FakeCallAudioSession.activate(speakerEnabled: speakerEnabled)
        } catch {
            completion()
            return
        }

        self.completion = completion

        if let audioFileURL,
           let player = try? AVAudioPlayer(contentsOf: audioFileURL) {
            filePlayer = player
            player.delegate = self
            player.prepareToPlay()

            if player.play() {
                return
            }

            filePlayer = nil
        }

        speak(text)
    }

    func stop() {
        completion = nil

        filePlayer?.stop()
        filePlayer = nil

        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        Task { @MainActor [weak self] in
            self?.finishPlayback()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(
        _ player: AVAudioPlayer,
        error: (any Error)?
    ) {
        Task { @MainActor [weak self] in
            self?.finishPlayback()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.finishPlayback()
        }
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = 0.46
        utterance.pitchMultiplier = 0.96
        utterance.preUtteranceDelay = 0.2

        synthesizer.speak(utterance)
    }

    private func finishPlayback() {
        filePlayer = nil
        let action = completion
        completion = nil
        action?()
    }
}

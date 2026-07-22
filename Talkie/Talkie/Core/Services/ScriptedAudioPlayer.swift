//
//  ScriptedAudioPlayer.swift
//  Talkie
//


@preconcurrency import AVFoundation

/// 상대 음성 재생과 마이크 입력이 공유하는 AVAudioSession 정책.
///
/// `.playAndRecord + .voiceChat`을 한 곳에서 적용해 재생기와 VAD가 서로 다른 category로
/// session을 덮어쓰지 않게 한다. MainActor 기본 격리 프로젝트에서도 오디오 서비스가
/// 안전하게 동기 호출할 수 있도록 상태를 소유하지 않는 이 namespace를 `nonisolated`로 둔다.
nonisolated enum FakeCallAudioSession {
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
        // 이미 원하는 설정이면 category를 다시 지정하지 않는다. 불필요한 route 재구성은
        // 짧은 무음/0바이트 버퍼를 만들 수 있으므로 실제 변경이 필요할 때만 갱신한다.
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
        // `.none`은 임의의 스피커를 선택한다는 뜻이 아니라 시스템 기본 통화 route
        // (수화부 또는 연결된 HFP 장치)로 복귀한다는 뜻이다.
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

        if let audioFileURL {
            guard let player = try? AVAudioPlayer(contentsOf: audioFileURL) else {
                finishPlayback()
                return
            }

            filePlayer = player
            player.delegate = self
            player.prepareToPlay()

            guard player.play() else {
                filePlayer = nil
                finishPlayback()
                return
            }
            return
        }

        // 오디오가 애초에 없는 mock/사용자 문장에만 TTS를 fallback으로 사용합니다.
        // 지정된 프리셋 파일이 손상됐을 때 다른 목소리로 바뀌는 일은 만들지 않습니다.
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

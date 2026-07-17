//
//  IncomingCallRingtoneService.swift
//  Talkie
//

@preconcurrency import AVFoundation
import Foundation
import OSLog

@MainActor
protocol IncomingCallRingtonePlaying: AnyObject {
    func prepareForRinging() async
    func startRinging(callerName: String) async
    func stopRinging()
}

@MainActor
final class IncomingCallRingtoneService: IncomingCallRingtonePlaying {
    static let shared = IncomingCallRingtoneService()

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Talkie",
        category: "IncomingCallRingtone"
    )
    private static let soundResourceName = "iphone_bell"
    private static let soundResourceExtension = "caf"

    private let audioSession = AVAudioSession.sharedInstance()
    private var audioPlayer: AVAudioPlayer?

    private init() {}

    func prepareForRinging() async {
        guard audioPlayer == nil else { return }

        do {
            let player = try makeAudioPlayer()
            configure(player)
            player.prepareToPlay()
            audioPlayer = player
        } catch {
            Self.logger.error(
                "벨소리 준비 실패: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func startRinging(callerName: String) async {
        audioPlayer?.stop()

        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)

            let player = try audioPlayer ?? makeAudioPlayer()
            configure(player)
            player.currentTime = 0
            player.prepareToPlay()

            guard player.play() else {
                throw RingtoneError.playbackDidNotStart
            }

            audioPlayer = player
        } catch {
            Self.logger.error(
                "\(callerName, privacy: .public) 벨소리 재생 실패: \(error.localizedDescription, privacy: .public)"
            )
            stopRinging()
        }
    }

    func stopRinging() {
        audioPlayer?.stop()
        audioPlayer = nil

        do {
            try audioSession.setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            Self.logger.error(
                "벨소리 오디오 세션 종료 실패: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func makeAudioPlayer() throws -> AVAudioPlayer {
        guard let url = Bundle.main.url(
            forResource: Self.soundResourceName,
            withExtension: Self.soundResourceExtension
        ) else {
            throw RingtoneError.missingBundledSound
        }

        return try AVAudioPlayer(contentsOf: url)
    }

    private func configure(_ player: AVAudioPlayer) {
        player.numberOfLoops = -1
        player.volume = 1
    }
}

private enum RingtoneError: LocalizedError {
    case missingBundledSound
    case playbackDidNotStart

    var errorDescription: String? {
        switch self {
        case .missingBundledSound:
            "앱 번들에서 iphone_bell.caf를 찾지 못했습니다."
        case .playbackDidNotStart:
            "AVAudioPlayer가 재생을 시작하지 못했습니다."
        }
    }
}

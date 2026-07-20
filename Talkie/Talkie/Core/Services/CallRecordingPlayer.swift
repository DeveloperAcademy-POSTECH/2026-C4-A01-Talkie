//
//  CallRecordingPlayer.swift
//  Talkie
//

@preconcurrency import AVFoundation
import Foundation
import Observation

/// 통화내역 화면에서 한 번에 하나의 녹음만 재생하도록 상태를 관리합니다.
@MainActor
@Observable
final class CallRecordingPlayer: NSObject, AVAudioPlayerDelegate {
    private(set) var activeRecordingID: UUID?
    private(set) var isPlaying = false
    private(set) var errorMessage: String?

    private let fileStore: CallRecordingFileStore
    private var audioPlayer: AVAudioPlayer?

    init(fileStore: CallRecordingFileStore = CallRecordingFileStore()) {
        self.fileStore = fileStore
        super.init()
    }

    func toggle(_ recording: CallRecording) {
        if activeRecordingID == recording.id, isPlaying {
            pause()
            return
        }

        if activeRecordingID == recording.id,
           let audioPlayer,
           audioPlayer.currentTime > 0 {
            if audioPlayer.play() {
                isPlaying = true
            }
            return
        }

        play(recording)
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        activeRecordingID = nil
        isPlaying = false
    }

    func clearError() {
        errorMessage = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        Task { @MainActor [weak self] in
            self?.stop()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(
        _ player: AVAudioPlayer,
        error: (any Error)?
    ) {
        Task { @MainActor [weak self] in
            self?.stop()
            self?.errorMessage = "녹음 파일을 재생하지 못했습니다."
        }
    }

    private func play(_ recording: CallRecording) {
        stop()

        do {
            guard try fileStore.fileExists(fileName: recording.fileName) else {
                errorMessage = "녹음 파일을 찾을 수 없습니다."
                return
            }

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let player = try AVAudioPlayer(
                contentsOf: fileStore.url(for: recording.fileName)
            )
            player.delegate = self
            player.prepareToPlay()

            guard player.play() else {
                errorMessage = "녹음 재생을 시작하지 못했습니다."
                return
            }

            audioPlayer = player
            activeRecordingID = recording.id
            isPlaying = true
        } catch {
            errorMessage = "녹음 파일을 재생하지 못했습니다."
        }
    }

    private func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
}

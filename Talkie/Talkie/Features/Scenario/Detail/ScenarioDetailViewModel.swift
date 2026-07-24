//
//  ScenarioDetailViewModel.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import Foundation
@preconcurrency import AVFoundation
import Observation
import SwiftData

@MainActor
@Observable
final class ScenarioDetailViewModel {
    /// 사용자 시나리오일 때만 원본 SwiftData 객체를 보유합니다.
    /// nil이면 Bundle 프리셋이므로 편집·삭제 경로를 열지 않습니다.
    private(set) var customScenario: Scenario?
    private(set) var content: ScenarioContent
    private(set) var isPlayingAll = false
    private(set) var playingLineID: String?
    private(set) var errorMessage: String?

    private var audioPlayer: AVAudioPlayer?
    private var playbackTask: Task<Void, Never>?
    private var playbackQueue: [ScenarioLineContent] = []

    init(scenario: Scenario) {
        customScenario = scenario
        content = scenario.content
    }

    init(preset: PresetScenario) {
        customScenario = nil
        content = preset.content
    }

    var canManageScenario: Bool {
        customScenario != nil
    }

    var sortedScriptLines: [ScenarioLineContent] {
        content.scriptLines.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// 편집 화면에서 돌아왔을 때 사용자 모델의 최신 값을 표시용 스냅숏에 반영합니다.
    func refreshContent() {
        guard let customScenario else { return }
        content = customScenario.content
    }

    func togglePlayAll() {
        if isPlayingAll {
            stopPlayback()
        } else {
            startPlayAll()
        }
    }

    func playSingleLine(_ line: ScenarioLineContent) {
        guard !isPlaying(line) else {
            stopPlayback()
            return
        }

        stopPlayback()
        play(line, shouldContinueQueue: false)
    }

    func isPlaying(_ line: ScenarioLineContent) -> Bool {
        playingLineID == line.id
    }

    func deleteScenario(using modelContext: ModelContext) -> Bool {
        guard let customScenario else {
            errorMessage = "기본 프리셋은 삭제할 수 없습니다."
            return false
        }

        stopPlayback()

        for scriptLine in customScenario.scriptLines {
            do {
                try AudioFileManager.deleteIfNeeded(fileName: scriptLine.audioFileName)
            } catch {
                errorMessage = "연결된 녹음 파일을 삭제하지 못했습니다."
                print("시나리오 오디오 파일 삭제 실패: \(error.localizedDescription)")
                return false
            }
        }

        let scenarioID = customScenario.id
        let scriptLineIDs = customScenario.scriptLines.map(\.id)
        modelContext.delete(customScenario)

        do {
            try modelContext.save()
            CloudSyncChangeTracker.deletedScenario(id: scenarioID, scriptLineIDs: scriptLineIDs)
            return true
        } catch {
            errorMessage = "시나리오를 삭제하지 못했습니다."
            print("시나리오 삭제 실패: \(error.localizedDescription)")
            return false
        }
    }

    func clearErrorMessage() {
        errorMessage = nil
    }

    func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        playingLineID = nil
        playbackQueue = []
        isPlayingAll = false
    }

    private func startPlayAll() {
        let playableLines = sortedScriptLines.filter { $0.audioSource != nil }

        guard !playableLines.isEmpty else {
            errorMessage = "재생할 녹음 파일이 없습니다."
            return
        }

        playbackQueue = playableLines
        isPlayingAll = true
        playNextLine()
    }

    private func playNextLine() {
        guard isPlayingAll else { return }

        guard !playbackQueue.isEmpty else {
            stopPlayback()
            return
        }

        let nextLine = playbackQueue.removeFirst()
        play(nextLine, shouldContinueQueue: true)
    }

    private func play(_ line: ScenarioLineContent, shouldContinueQueue: Bool) {
        guard let audioSource = line.audioSource else {
            errorMessage = "아직 녹음된 대사가 없습니다."
            stopPlayback()
            return
        }

        do {
            let audioURL = try ScenarioAudioResolver.url(for: audioSource)
            try configureAudioSessionForPlayback()

            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            guard audioPlayer?.play() == true else {
                throw ScenarioAudioResolverError.playbackFailed(audioURL.lastPathComponent)
            }
            playingLineID = line.id

            schedulePlaybackCompletion(shouldContinueQueue: shouldContinueQueue)
        } catch {
            errorMessage = error.localizedDescription
            print("상세 화면 오디오 재생 실패: \(error.localizedDescription)")
            stopPlayback()
        }
    }

    private func schedulePlaybackCompletion(shouldContinueQueue: Bool) {
        playbackTask?.cancel()

        guard let duration = audioPlayer?.duration else { return }

        playbackTask = Task {
            let nanoseconds = UInt64(max(duration, 0.1) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                if shouldContinueQueue {
                    self.playNextLine()
                } else {
                    self.stopPlayback()
                }
            }
        }
    }

    private func configureAudioSessionForPlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }
}

extension ScenarioDetailViewModel: @unchecked Sendable {}

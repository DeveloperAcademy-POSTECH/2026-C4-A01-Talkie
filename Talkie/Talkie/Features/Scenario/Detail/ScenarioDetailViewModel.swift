//
//  ScenarioDetailViewModel.swift
//  Talkie
//
//  Created by Codex on 7/21/26.
//

import Foundation
@preconcurrency import AVFoundation
import Observation
import SwiftData

@MainActor
@Observable
final class ScenarioDetailViewModel {
    var scenario: Scenario
    private(set) var isPlayingAll = false
    private(set) var playingScriptLine: ScriptLine?
    private(set) var errorMessage: String?

    private var audioPlayer: AVAudioPlayer?
    private var playbackTask: Task<Void, Never>?
    private var playbackQueue: [ScriptLine] = []

    init(scenario: Scenario) {
        self.scenario = scenario
    }

    var isPresetScenario: Bool {
        scenario.presetID != nil
    }

    var canManageScenario: Bool {
        !isPresetScenario
    }

    var sortedScriptLines: [ScriptLine] {
        scenario.scriptLines.sorted {
            $0.sortOrder < $1.sortOrder
        }
    }

    var callerName: String {
        scenario.callerProfile.name
    }

    func togglePlayAll() {
        if isPlayingAll {
            stopPlayback()
        } else {
            startPlayAll()
        }
    }

    func playSingleLine(_ scriptLine: ScriptLine) {
        guard !isPlaying(scriptLine) else {
            stopPlayback()
            return
        }

        stopPlayback()
        play(scriptLine, shouldContinueQueue: false)
    }

    func isPlaying(_ scriptLine: ScriptLine) -> Bool {
        playingScriptLine === scriptLine
    }

    func deleteScenario(using modelContext: ModelContext) -> Bool {
        stopPlayback()

        for scriptLine in scenario.scriptLines {
            do {
                try AudioFileManager.deleteIfNeeded(fileName: scriptLine.audioFileName)
            } catch {
                errorMessage = "연결된 녹음 파일을 삭제하지 못했습니다."
                print("시나리오 오디오 파일 삭제 실패: \(error.localizedDescription)")
                return false
            }
        }

        modelContext.delete(scenario)

        do {
            try modelContext.save()
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

    private func startPlayAll() {
        let recordedLines = sortedScriptLines.filter {
            $0.isRecorded && $0.audioFileName != nil
        }

        guard !recordedLines.isEmpty else {
            errorMessage = "재생할 녹음 파일이 없습니다."
            return
        }

        playbackQueue = recordedLines
        isPlayingAll = true
        playNextLine()
    }

    private func playNextLine() {
        guard isPlayingAll else {
            return
        }

        guard !playbackQueue.isEmpty else {
            stopPlayback()
            return
        }

        let nextLine = playbackQueue.removeFirst()
        play(nextLine, shouldContinueQueue: true)
    }

    private func play(_ scriptLine: ScriptLine, shouldContinueQueue: Bool) {
        guard scriptLine.isRecorded else {
            errorMessage = "아직 녹음된 대사가 없습니다."
            isPlayingAll = false
            return
        }

        guard let audioFileName = scriptLine.audioFileName else {
            errorMessage = "녹음 파일 이름이 저장되어 있지 않습니다."
            isPlayingAll = false
            return
        }

        do {
            guard try AudioFileManager.fileExists(fileName: audioFileName) else {
                errorMessage = "녹음 파일을 찾을 수 없습니다."
                isPlayingAll = false
                return
            }

            let audioURL = try AudioFileManager.url(for: audioFileName)
            try configureAudioSessionForPlayback()

            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            playingScriptLine = scriptLine

            schedulePlaybackCompletion(shouldContinueQueue: shouldContinueQueue)
        } catch {
            errorMessage = "녹음 파일을 재생하지 못했습니다."
            print("상세 화면 오디오 재생 실패: \(error.localizedDescription)")
            stopPlayback()
        }
    }

    private func schedulePlaybackCompletion(shouldContinueQueue: Bool) {
        playbackTask?.cancel()

        guard let duration = audioPlayer?.duration else {
            return
        }

        playbackTask = Task {
            let nanoseconds = UInt64(max(duration, 0.1) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                if shouldContinueQueue {
                    self.playNextLine()
                } else {
                    self.stopPlayback()
                }
            }
        }
    }

    private func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        playingScriptLine = nil
        playbackQueue = []
        isPlayingAll = false
    }

    private func configureAudioSessionForPlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }
}

extension ScenarioDetailViewModel: @unchecked Sendable {}

//
//  ScriptEditViewModel.swift
//  Talkie
//
//  Created by DS on 7/18/26.
//
import Foundation
import SwiftData
import Observation

@Observable
final class ScriptEditViewModel {
    private let modelContext: ModelContext

    var scenario: Scenario
    private(set) var recordingScriptLine: ScriptLine?
    private(set) var errorMessage: String?

    init(
        scenario: Scenario,
        modelContext: ModelContext
    ) {
        self.scenario = scenario
        self.modelContext = modelContext
    }

    // MARK: - View Data

    var sortedScriptLines: [ScriptLine] {
        scenario.scriptLines.sorted {
            $0.sortOrder < $1.sortOrder
        }
    }

    var recordedCount: Int {
        scenario.scriptLines.filter(\.isRecorded).count
    }

    var totalCount: Int {
        scenario.scriptLines.count
    }

    // MARK: - Recording

    func toggleRecording(for scriptLine: ScriptLine) {
        if isRecording(scriptLine) {
            stopRecording(for: scriptLine)
        } else {
            startRecording(for: scriptLine)
        }
    }

    func startRecording(for scriptLine: ScriptLine) {
        errorMessage = nil
        recordingScriptLine = scriptLine
    }

    func stopRecording(for scriptLine: ScriptLine) {
        guard isRecording(scriptLine) else {
            return
        }

        scriptLine.isRecorded = true
        recordingScriptLine = nil

        saveChanges()
    }

    func isRecording(_ scriptLine: ScriptLine) -> Bool {
        recordingScriptLine === scriptLine
    }
    
    func playRecording(for scriptLine: ScriptLine) {
        guard scriptLine.isRecorded else {
            return
        }
        
        // TODO: AudioClipMetadata와 실제 오디오 파일 연결 후 재생 로직을 구현합니다.
    }

    // MARK: - Persistence

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "녹음 상태를 저장하지 못했습니다."
            print("녹음 상태 저장 실패: \(error.localizedDescription)")
        }
    }
}

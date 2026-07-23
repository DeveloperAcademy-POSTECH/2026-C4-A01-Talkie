//
//  ScriptEditViewModel.swift
//  Talkie
//
//  Created by DS on 7/18/26.
//
import Foundation
@preconcurrency import AVFoundation
import SwiftData
import Observation
import SwiftUI

@MainActor
@Observable
final class ScriptEditViewModel {
    private let modelContext: ModelContext
    private let insertsScenarioOnComplete: Bool
    private var hasInsertedScenario = false
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var playbackTask: Task<Void, Never>?
    private var recordingFileName: String?
    private var pendingPermissionScriptLine: ScriptLine?

    var scenario: Scenario
    private(set) var recordingScriptLine: ScriptLine?
    private(set) var playingScriptLine: ScriptLine?
    private(set) var errorMessage: String?

    init(
        scenario: Scenario,
        modelContext: ModelContext,
        insertsScenarioOnComplete: Bool = false
    ) {
        self.scenario = scenario
        self.modelContext = modelContext
        self.insertsScenarioOnComplete = insertsScenarioOnComplete
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

    var isPresetScenario: Bool {
        scenario.presetID != nil
    }

    var canEditScripts: Bool {
        !isPresetScenario
    }

    // MARK: - Recording

    func toggleRecording(for scriptLine: ScriptLine) {
        guard canEditScripts else {
            errorMessage = "기본 제공 시나리오는 녹음 상태를 변경할 수 없습니다."
            return
        }

        if isRecording(scriptLine) {
            stopRecording(for: scriptLine)
        } else {
            startRecording(for: scriptLine)
        }
    }

    func startRecording(for scriptLine: ScriptLine) {
        guard canEditScripts else {
            errorMessage = "기본 제공 시나리오는 녹음 상태를 변경할 수 없습니다."
            return
        }

        errorMessage = nil
        stopPlayback()
        
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            startRecordingAfterPermissionGranted(for: scriptLine)
        case .denied:
            errorMessage = "마이크 권한이 꺼져 있어 녹음할 수 없습니다. 설정 앱에서 마이크 권한을 허용해주세요."
        case .undetermined:
            requestMicrophonePermission(for: scriptLine)
        @unknown default:
            errorMessage = "마이크 권한 상태를 확인할 수 없습니다."
        }
    }

    func stopRecording(for scriptLine: ScriptLine) {
        guard canEditScripts else {
            errorMessage = "기본 제공 시나리오는 녹음 상태를 변경할 수 없습니다."
            return
        }

        guard isRecording(scriptLine) else {
            return
        }
        
        audioRecorder?.stop()
        audioRecorder = nil
        
        if let recordingFileName {
            scriptLine.audioFileName = recordingFileName
            scriptLine.isRecorded = true
        } else {
            scriptLine.isRecorded = false
        }
        
        recordingFileName = nil
        recordingScriptLine = nil

        saveChanges()
    }

    func isRecording(_ scriptLine: ScriptLine) -> Bool {
        recordingScriptLine === scriptLine
    }

    func isPlaying(_ scriptLine: ScriptLine) -> Bool {
        playingScriptLine === scriptLine
    }
    
    func playRecording(for scriptLine: ScriptLine) {
        if isPlaying(scriptLine) {
            stopPlayback()
            return
        }

        playAudio(for: scriptLine)
    }
    
    // MARK: - Script Editing
    
    func updateText(_ text: String, for scriptLine: ScriptLine) {
        guard canEditScripts else {
            errorMessage = "기본 제공 시나리오는 수정할 수 없습니다."
            return
        }

        scriptLine.text = text
        saveChanges()
    }
    
    func addScriptLine() {
        guard canEditScripts else {
            errorMessage = "기본 제공 시나리오에는 대사를 추가할 수 없습니다."
            return
        }

        let scriptLine = ScriptLine(
            text: "",
            sortOrder: scenario.scriptLines.count,
            scenario: scenario
        )
        
        scenario.scriptLines.append(scriptLine)
        reassignSortOrders()
        saveChanges()
    }
    
    func deleteScriptLine(_ scriptLine: ScriptLine) {
        guard canEditScripts else {
            errorMessage = "기본 제공 시나리오는 삭제할 수 없습니다."
            return
        }

        if isRecording(scriptLine) {
            cancelCurrentRecording()
        }
        
        do {
            try AudioFileManager.deleteIfNeeded(fileName: scriptLine.audioFileName)
        } catch {
            errorMessage = "연결된 녹음 파일을 삭제하지 못했습니다."
            print("오디오 파일 삭제 실패: \(error.localizedDescription)")
        }
        
        scenario.scriptLines.removeAll { $0 === scriptLine }
        deleteFromModelContextIfNeeded(scriptLine)
        reassignSortOrders()
        saveChanges()
    }

    func deleteScriptLines(at offsets: IndexSet) {
        guard canEditScripts else {
            errorMessage = "기본 제공 시나리오는 삭제할 수 없습니다."
            return
        }

        let linesToDelete = offsets.compactMap { index in
            sortedScriptLines[safe: index]
        }

        linesToDelete.forEach { scriptLine in
            deleteScriptLine(scriptLine)
        }
    }
    
    func moveScriptLine(_ source: ScriptLine, before destination: ScriptLine) {
        guard canEditScripts else {
            errorMessage = "기본 제공 시나리오의 순서는 변경할 수 없습니다."
            return
        }

        var lines = sortedScriptLines
        
        guard
            let sourceIndex = lines.firstIndex(where: { $0 === source }),
            let destinationIndex = lines.firstIndex(where: { $0 === destination }),
            sourceIndex != destinationIndex
        else {
            return
        }
        
        let movedLine = lines.remove(at: sourceIndex)
        let adjustedDestinationIndex = sourceIndex < destinationIndex ? destinationIndex - 1 : destinationIndex
        lines.insert(movedLine, at: adjustedDestinationIndex)
        scenario.scriptLines = lines
        reassignSortOrders()
        saveChanges()
    }

    func moveScriptLines(from source: IndexSet, to destination: Int) {
        guard canEditScripts else {
            errorMessage = "기본 제공 시나리오의 순서는 변경할 수 없습니다."
            return
        }

        var lines = sortedScriptLines
        lines.move(fromOffsets: source, toOffset: destination)
        scenario.scriptLines = lines
        reassignSortOrders()
        saveChanges()
    }
    
    func playAudio(for scriptLine: ScriptLine) {
        guard scriptLine.isRecorded else {
            errorMessage = "아직 녹음된 대사가 없습니다."
            return
        }
        
        guard let audioFileName = scriptLine.audioFileName else {
            errorMessage = "녹음 파일 이름이 저장되어 있지 않습니다."
            return
        }
        
        do {
            guard try AudioFileManager.fileExists(fileName: audioFileName) else {
                errorMessage = "녹음 파일을 찾을 수 없습니다. 다시 녹음해주세요."
                return
            }
            
            if recordingScriptLine != nil {
                cancelCurrentRecording()
            }

            stopPlayback()
            
            let audioURL = try AudioFileManager.url(for: audioFileName)
            try configureAudioSessionForPlayback()
            
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            guard audioPlayer?.play() == true else {
                errorMessage = "녹음 파일을 재생하지 못했습니다."
                return
            }

            playingScriptLine = scriptLine
            schedulePlaybackCompletion()
        } catch {
            errorMessage = "녹음 파일을 재생하지 못했습니다."
            print("오디오 재생 실패: \(error.localizedDescription)")
        }
    }
    
    func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        playingScriptLine = nil
    }
    
    func completeEditing() -> Bool {
        if recordingScriptLine != nil {
            cancelCurrentRecording()
        }
        
        stopPlayback()
        insertScenarioIfNeeded()
        return saveChanges()
    }
    
    func clearErrorMessage() {
        errorMessage = nil
    }
    
    private func requestMicrophonePermission(for scriptLine: ScriptLine) {
        pendingPermissionScriptLine = scriptLine

        Task { @MainActor in
            let isGranted = await AVAudioApplication.requestRecordPermission()

            if isGranted {
                if let scriptLine = self.pendingPermissionScriptLine {
                    self.startRecordingAfterPermissionGranted(for: scriptLine)
                }
            } else {
                self.errorMessage = "마이크 권한이 없어 녹음할 수 없습니다."
            }

            self.pendingPermissionScriptLine = nil
        }
    }
    
    private func startRecordingAfterPermissionGranted(for scriptLine: ScriptLine) {
        // 한 번에 하나의 대사만 녹음합니다.
        // 다른 대사가 녹음 중이었다면, 기존 녹음은 완료 처리한 뒤 새 녹음을 시작합니다.
        if let currentScriptLine = recordingScriptLine, currentScriptLine !== scriptLine {
            stopRecording(for: currentScriptLine)
        }
        
        do {
            try configureAudioSessionForRecording()
            try AudioFileManager.deleteIfNeeded(fileName: scriptLine.audioFileName)
            
            let newFileName = AudioFileManager.makeFileName()
            let audioURL = try AudioFileManager.url(for: newFileName)
            
            audioRecorder = try AVAudioRecorder(
                url: audioURL,
                settings: recordingSettings
            )
            audioRecorder?.prepareToRecord()
            
            guard audioRecorder?.record() == true else {
                try AudioFileManager.delete(fileName: newFileName)
                errorMessage = "녹음을 시작하지 못했습니다."
                return
            }
            
            scriptLine.audioFileName = nil
            scriptLine.isRecorded = false
            recordingFileName = newFileName
            recordingScriptLine = scriptLine
            saveChanges()
        } catch {
            cleanupFailedRecording()
            errorMessage = "녹음을 시작하지 못했습니다."
            print("오디오 녹음 시작 실패: \(error.localizedDescription)")
        }
    }
    
    private func cancelCurrentRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        
        cleanupFailedRecording()
        recordingScriptLine = nil
    }
    
    private func cleanupFailedRecording() {
        do {
            try AudioFileManager.deleteIfNeeded(fileName: recordingFileName)
        } catch {
            print("임시 녹음 파일 삭제 실패: \(error.localizedDescription)")
        }
        
        recordingFileName = nil
    }

    private func schedulePlaybackCompletion() {
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
                self.stopPlayback()
            }
        }
    }
    
    private func configureAudioSessionForRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
    }
    
    private func configureAudioSessionForPlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }
    
    private var recordingSettings: [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }
    
    private func reassignSortOrders() {
        for (index, scriptLine) in sortedScriptLines.enumerated() {
            scriptLine.sortOrder = index
        }
    }

    // MARK: - Persistence

    private func insertScenarioIfNeeded() {
        guard insertsScenarioOnComplete, !hasInsertedScenario else {
            return
        }

        modelContext.insert(scenario)
        hasInsertedScenario = true
    }

    private func deleteFromModelContextIfNeeded(_ scriptLine: ScriptLine) {
        guard !insertsScenarioOnComplete || hasInsertedScenario else {
            return
        }

        modelContext.delete(scriptLine)
    }

    @discardableResult
    private func saveChanges() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            errorMessage = "녹음 상태를 저장하지 못했습니다."
            print("녹음 상태 저장 실패: \(error.localizedDescription)")
            return false
        }
    }
}

extension ScriptEditViewModel: @unchecked Sendable {}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

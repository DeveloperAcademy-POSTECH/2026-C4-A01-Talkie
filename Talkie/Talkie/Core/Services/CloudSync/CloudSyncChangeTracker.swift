//
//  CloudSyncChangeTracker.swift
//  Talkie
//
//  Converts successful SwiftData writes into durable cloud-sync intentions.
//

import Foundation

enum CloudSyncChangeTracker {
    static func savedScenario(
        _ scenario: Scenario,
        includeScriptLines: Bool = true,
        includeAudio: Bool = true,
        notifyCoordinator: Bool = true
    ) {
        guard scenario.presetID == nil else { return }

        var changes = [
            CloudSyncChange(
                recordType: .scenario,
                localID: scenario.id,
                operation: .save,
                changedAt: scenario.updatedAt
            )
        ]

        if includeScriptLines {
            for line in scenario.scriptLines {
                changes.append(
                    CloudSyncChange(
                        recordType: .scriptLine,
                        localID: line.id,
                        operation: .save,
                        changedAt: line.updatedAt
                    )
                )
                if includeAudio {
                    changes.append(
                        CloudSyncChange(
                            recordType: .scenarioAudio,
                            localID: line.id,
                            operation: line.isRecorded && line.audioFileName != nil ? .save : .delete,
                            changedAt: line.updatedAt
                        )
                    )
                }
            }
        }

        CloudSyncJournal.shared.enqueue(changes, notifyCoordinator: notifyCoordinator)
    }

    static func savedScriptLineAudio(_ line: ScriptLine) {
        CloudSyncJournal.shared.enqueue(
            line.isRecorded && line.audioFileName != nil ? .save : .delete,
            type: .scenarioAudio,
            id: line.id,
            changedAt: line.updatedAt
        )
    }

    static func deletedScenario(id: UUID, scriptLineIDs: [UUID]) {
        let now = Date()
        var changes = [
            CloudSyncChange(recordType: .scenario, localID: id, operation: .delete, changedAt: now)
        ]

        for lineID in scriptLineIDs {
            changes.append(CloudSyncChange(recordType: .scriptLine, localID: lineID, operation: .delete, changedAt: now))
            changes.append(CloudSyncChange(recordType: .scenarioAudio, localID: lineID, operation: .delete, changedAt: now))
        }
        CloudSyncJournal.shared.enqueue(changes)
    }

    static func deletedScriptLine(id: UUID) {
        let now = Date()
        CloudSyncJournal.shared.enqueue([
            CloudSyncChange(recordType: .scriptLine, localID: id, operation: .delete, changedAt: now),
            CloudSyncChange(recordType: .scenarioAudio, localID: id, operation: .delete, changedAt: now)
        ])
    }

    static func savedSafetyContact(_ contact: SafetyContact, notifyCoordinator: Bool = true) {
        CloudSyncJournal.shared.enqueue(
            [
                CloudSyncChange(
                    recordType: .safetyContact,
                    localID: contact.id,
                    operation: .save,
                    changedAt: contact.updatedAt
                )
            ],
            notifyCoordinator: notifyCoordinator
        )
    }

    static func deletedSafetyContact(id: UUID) {
        CloudSyncJournal.shared.enqueue(.delete, type: .safetyContact, id: id)
    }

    /// 녹음 파일이 있는 통화만 하나의 CloudKit 레코드로 동기화합니다.
    /// 레코드 ID는 세션 ID를 사용하므로 여러 기기에서 같은 통화를 중복 생성하지 않습니다.
    static func savedCallSession(
        _ session: CallSession,
        notifyCoordinator: Bool = true
    ) {
        guard
            session.recording != nil,
            UserDefaults.standard.bool(forKey: TalkiePreferenceKey.didAcknowledgeICloudRecordingSync)
        else { return }
        CloudSyncJournal.shared.enqueue(
            [
                CloudSyncChange(
                    recordType: .callRecording,
                    localID: session.id,
                    operation: .save,
                    changedAt: session.endedAt
                )
            ],
            notifyCoordinator: notifyCoordinator
        )
    }

    static func deletedCallSession(id: UUID) {
        CloudSyncJournal.shared.enqueue(.delete, type: .callRecording, id: id)
    }
}

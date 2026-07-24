//
//  CloudSyncRecord.swift
//  Talkie
//
//  Local-to-CloudKit record identity shared by the change journal and sync engine.
//

import CloudKit
import Foundation

enum CloudSyncRecordType: String, Codable, CaseIterable, Sendable {
    case scenario = "TLScenario"
    case scriptLine = "TLScriptLine"
    case scenarioAudio = "TLScenarioAudio"
    case safetyContact = "TLSafetyContact"
    case callRecording = "TLCallRecording"
}

enum CloudSyncOperation: String, Codable, Sendable {
    case save
    case delete
}

struct CloudSyncChange: Codable, Equatable, Sendable {
    let recordType: CloudSyncRecordType
    let localID: UUID
    let operation: CloudSyncOperation
    let changedAt: Date

    var recordName: String {
        "\(recordType.rawValue)-\(localID.uuidString.lowercased())"
    }

    func recordID(in zoneID: CKRecordZone.ID) -> CKRecord.ID {
        CKRecord.ID(recordName: recordName, zoneID: zoneID)
    }
}

extension Notification.Name {
    static let cloudSyncJournalDidChange = Notification.Name("CloudSyncJournalDidChange")
}

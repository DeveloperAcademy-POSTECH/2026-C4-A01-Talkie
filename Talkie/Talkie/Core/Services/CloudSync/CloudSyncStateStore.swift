//
//  CloudSyncStateStore.swift
//  Talkie
//
//  Stores CKSyncEngine's opaque state and CKRecord system fields locally.
//

import CloudKit
import Foundation

final class CloudSyncStateStore: @unchecked Sendable {
    private struct Payload: Codable {
        var engineState: Data?
        var recordSystemFields: [String: Data] = [:]
        var didCreateZone = false
    }

    private let lock = NSLock()
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL
    }

    func engineState() -> CKSyncEngine.State.Serialization? {
        lock.withLock {
            guard let data = loadUnlocked().engineState else { return nil }
            return try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: data)
        }
    }

    func save(engineState: CKSyncEngine.State.Serialization) {
        lock.withLock {
            var payload = loadUnlocked()
            payload.engineState = try? JSONEncoder().encode(engineState)
            try? persistUnlocked(payload)
        }
    }

    func didCreateZone() -> Bool {
        lock.withLock { loadUnlocked().didCreateZone }
    }

    func markZoneCreated() {
        lock.withLock {
            var payload = loadUnlocked()
            payload.didCreateZone = true
            try? persistUnlocked(payload)
        }
    }

    func baseRecord(for recordID: CKRecord.ID, recordType: CKRecord.RecordType) -> CKRecord {
        lock.withLock {
            let payload = loadUnlocked()
            guard
                let data = payload.recordSystemFields[recordID.recordName],
                let coder = try? NSKeyedUnarchiver(forReadingFrom: data),
                let record = CKRecord(coder: coder)
            else {
                return CKRecord(recordType: recordType, recordID: recordID)
            }
            coder.finishDecoding()
            return record
        }
    }

    func saveSystemFields(for record: CKRecord) {
        lock.withLock {
            var payload = loadUnlocked()
            let coder = NSKeyedArchiver(requiringSecureCoding: true)
            record.encodeSystemFields(with: coder)
            coder.finishEncoding()
            payload.recordSystemFields[record.recordID.recordName] = coder.encodedData
            try? persistUnlocked(payload)
        }
    }

    func removeSystemFields(for recordNames: Set<String>) {
        lock.withLock {
            var payload = loadUnlocked()
            recordNames.forEach { payload.recordSystemFields.removeValue(forKey: $0) }
            try? persistUnlocked(payload)
        }
    }

    private func loadUnlocked() -> Payload {
        guard let data = try? Data(contentsOf: fileURL) else { return Payload() }
        return (try? JSONDecoder().decode(Payload.self, from: data)) ?? Payload()
    }

    private func persistUnlocked(_ payload: Payload) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(payload)
        try data.write(to: fileURL, options: .atomic)
    }

    private static var defaultFileURL: URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return applicationSupport
            .appendingPathComponent("Talkie", isDirectory: true)
            .appendingPathComponent("CloudSyncState.json")
    }
}

private extension NSLock {
    func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try operation()
    }
}

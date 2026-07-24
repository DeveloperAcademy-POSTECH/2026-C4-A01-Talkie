//
//  CloudSyncJournal.swift
//  Talkie
//
//  Persists local mutations even while iCloud sync is disabled.
//

import Foundation
import OSLog

final class CloudSyncJournal: @unchecked Sendable {
    static let shared = CloudSyncJournal()

    private let lock = NSLock()
    private let fileURL: URL
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Talkie", category: "CloudSyncJournal")

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL
    }

    func enqueue(
        _ operation: CloudSyncOperation,
        type: CloudSyncRecordType,
        id: UUID,
        changedAt: Date = Date()
    ) {
        enqueue([
            CloudSyncChange(
                recordType: type,
                localID: id,
                operation: operation,
                changedAt: changedAt
            )
        ])
    }

    func enqueue(_ changes: [CloudSyncChange], notifyCoordinator: Bool = true) {
        guard !changes.isEmpty else { return }

        lock.lock()
        defer { lock.unlock() }

        var current = loadUnlocked()
        for change in changes {
            // One record needs only its latest desired state. A delete followed by a
            // save becomes a save; repeated edits collapse into one upload.
            current[change.recordName] = change
        }

        do {
            try persistUnlocked(current)
            if notifyCoordinator {
                NotificationCenter.default.post(name: .cloudSyncJournalDidChange, object: nil)
            }
        } catch {
            logger.error("Failed to persist cloud sync journal: \(error.localizedDescription, privacy: .public)")
        }
    }

    func pendingChanges() -> [CloudSyncChange] {
        lock.lock()
        defer { lock.unlock() }
        return loadUnlocked().values.sorted { $0.changedAt < $1.changedAt }
    }

    func remove(recordNames: Set<String>) {
        guard !recordNames.isEmpty else { return }

        lock.lock()
        defer { lock.unlock() }

        var current = loadUnlocked()
        recordNames.forEach { current.removeValue(forKey: $0) }

        do {
            try persistUnlocked(current)
        } catch {
            logger.error("Failed to update cloud sync journal: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadUnlocked() -> [String: CloudSyncChange] {
        guard let data = try? Data(contentsOf: fileURL) else { return [:] }

        do {
            return try JSONDecoder().decode([String: CloudSyncChange].self, from: data)
        } catch {
            logger.error("Failed to decode cloud sync journal: \(error.localizedDescription, privacy: .public)")
            return [:]
        }
    }

    private func persistUnlocked(_ changes: [String: CloudSyncChange]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(changes)
        try data.write(to: fileURL, options: .atomic)
    }

    private static var defaultFileURL: URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return applicationSupport
            .appendingPathComponent("Talkie", isDirectory: true)
            .appendingPathComponent("CloudSyncJournal.json")
    }
}

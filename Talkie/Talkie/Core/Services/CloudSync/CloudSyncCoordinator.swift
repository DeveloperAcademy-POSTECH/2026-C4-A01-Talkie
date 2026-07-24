//
//  CloudSyncCoordinator.swift
//  Talkie
//
//  Coordinates opt-in CloudKit sync while SwiftData remains the local source of truth.
//

import CloudKit
import Foundation
import Observation
import OSLog
import SwiftData

@MainActor
@Observable
final class CloudSyncCoordinator {
    enum Status: Equatable {
        case disabled
        case checkingAccount
        case syncing
        case synced(Date)
        case unavailable(String)
        case failed(String)

        var message: String {
            switch self {
            case .disabled:
                return "이 기기의 데이터만 사용합니다."
            case .checkingAccount:
                return "iCloud 계정을 확인하고 있습니다."
            case .syncing:
                return "iCloud와 동기화하고 있습니다."
            case .synced:
                return "iCloud 동기화가 완료되었습니다."
            case .unavailable(let message), .failed(let message):
                return message
            }
        }
    }

    private static let zoneName = "TalkieUserData"

    private let modelContainer: ModelContainer
    private let cloudContainer: CKContainer
    private let journal: CloudSyncJournal
    private let stateStore: CloudSyncStateStore
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Talkie", category: "CloudSync")
    private let delegateBridge = CloudSyncEngineDelegateBridge()
    private var syncEngine: CKSyncEngine?
    private var journalObserver: NSObjectProtocol?
    private var syncTask: Task<Void, Never>?

    private(set) var isEnabled: Bool
    private(set) var status: Status

    private var zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: Self.zoneName, ownerName: CKCurrentUserDefaultName)
    }

    init(
        modelContainer: ModelContainer,
        cloudContainer: CKContainer = .default()
    ) {
        self.modelContainer = modelContainer
        self.cloudContainer = cloudContainer
        self.journal = .shared
        self.stateStore = CloudSyncStateStore()

        let storedValue = UserDefaults.standard.bool(forKey: TalkiePreferenceKey.iCloudSyncEnabled)
        isEnabled = storedValue
        status = storedValue ? .checkingAccount : .disabled

        delegateBridge.coordinator = self
        journalObserver = NotificationCenter.default.addObserver(
            forName: .cloudSyncJournalDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scheduleSync()
            }
        }
    }

    func startIfNeeded() {
        guard isEnabled else { return }
        scheduleSync(rebuildEngine: true, includeFullLocalSnapshot: false)
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }

        if enabled {
            isEnabled = true
            status = .checkingAccount
            UserDefaults.standard.set(true, forKey: TalkiePreferenceKey.iCloudSyncEnabled)
            scheduleSync(rebuildEngine: true, includeFullLocalSnapshot: true)
        } else {
            isEnabled = false
            status = .disabled
            UserDefaults.standard.set(false, forKey: TalkiePreferenceKey.iCloudSyncEnabled)
            syncTask?.cancel()
            syncTask = nil

            let engine = syncEngine
            syncEngine = nil
            Task {
                await engine?.cancelOperations()
            }
        }
    }

    func syncNow() {
        guard isEnabled else { return }
        scheduleSync()
    }

    private func scheduleSync(
        rebuildEngine: Bool = false,
        includeFullLocalSnapshot: Bool = false
    ) {
        guard isEnabled else { return }

        syncTask?.cancel()
        syncTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                if rebuildEngine || syncEngine == nil {
                    try await prepareEngine()
                }

                guard !Task.isCancelled, isEnabled else { return }

                if includeFullLocalSnapshot {
                    enqueueFullLocalSnapshot()
                }
                addJournalChangesToEngine()

                status = .syncing
                try await syncEngine?.fetchChanges()
                guard !Task.isCancelled, isEnabled else { return }
                try await syncEngine?.sendChanges()
                guard !Task.isCancelled, isEnabled else { return }
                status = .synced(Date())
            } catch is CancellationError {
                // Turning the toggle off intentionally cancels in-flight work.
            } catch {
                handleSyncError(error)
            }
        }
    }

    private func prepareEngine() async throws {
        let accountStatus = try await cloudContainer.accountStatus()
        guard accountStatus == .available else {
            isEnabled = false
            UserDefaults.standard.set(false, forKey: TalkiePreferenceKey.iCloudSyncEnabled)
            throw CloudSyncError.accountUnavailable
        }

        var configuration = CKSyncEngine.Configuration(
            database: cloudContainer.privateCloudDatabase,
            stateSerialization: stateStore.engineState(),
            delegate: delegateBridge
        )
        configuration.automaticallySync = true
        let engine = CKSyncEngine(configuration)
        syncEngine = engine

        if !stateStore.didCreateZone() {
            let pendingChange = CKSyncEngine.PendingDatabaseChange.saveZone(
                CKRecordZone(zoneID: zoneID)
            )
            if !engine.state.pendingDatabaseChanges.contains(pendingChange) {
                engine.state.add(pendingDatabaseChanges: [pendingChange])
            }
        }
    }

    private func enqueueFullLocalSnapshot() {
        let context = ModelContext(modelContainer)

        do {
            let scenarios = try context.fetch(FetchDescriptor<Scenario>())
                .filter { $0.presetID == nil }
            scenarios.forEach {
                CloudSyncChangeTracker.savedScenario($0, notifyCoordinator: false)
            }

            let contacts = try context.fetch(FetchDescriptor<SafetyContact>())
            contacts.forEach {
                CloudSyncChangeTracker.savedSafetyContact($0, notifyCoordinator: false)
            }
        } catch {
            logger.error("Failed to create local sync snapshot: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func addJournalChangesToEngine() {
        guard let syncEngine else { return }

        let existing = Set(syncEngine.state.pendingRecordZoneChanges)
        let additions = journal.pendingChanges().compactMap { change -> CKSyncEngine.PendingRecordZoneChange? in
            let recordID = change.recordID(in: zoneID)
            let pending: CKSyncEngine.PendingRecordZoneChange = switch change.operation {
            case .save: .saveRecord(recordID)
            case .delete: .deleteRecord(recordID)
            }
            return existing.contains(pending) ? nil : pending
        }
        syncEngine.state.add(pendingRecordZoneChanges: additions)
    }

    fileprivate func nextRecordZoneChangeBatch(
        context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let pending = syncEngine.state.pendingRecordZoneChanges.filter {
            context.options.scope.contains($0)
        }

        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pending) { [weak self] recordID in
            guard let self else { return nil }
            return await self.recordToSave(for: recordID)
        }
    }

    fileprivate func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        guard isEnabled else { return }

        switch event {
        case .stateUpdate(let update):
            stateStore.save(engineState: update.stateSerialization)

        case .accountChange(let change):
            switch change.changeType {
            case .signIn:
                scheduleSync(includeFullLocalSnapshot: true)
            case .signOut, .switchAccounts:
                status = .unavailable("iCloud 계정이 변경되었습니다. 다시 동기화해 주세요.")
            @unknown default:
                status = .unavailable("iCloud 계정 상태를 다시 확인해 주세요.")
            }

        case .fetchedRecordZoneChanges(let changes):
            applyFetchedChanges(changes)

        case .sentRecordZoneChanges(let changes):
            handleSentRecordChanges(changes, syncEngine: syncEngine)

        case .sentDatabaseChanges(let changes):
            if changes.savedZones.contains(where: { $0.zoneID == zoneID }) {
                stateStore.markZoneCreated()
            }
            if !changes.failedZoneSaves.isEmpty || !changes.failedZoneDeletes.isEmpty {
                status = .failed("iCloud 저장 공간을 준비하지 못했습니다.")
            }

        case .didFetchChanges, .didSendChanges:
            status = .synced(Date())

        default:
            break
        }
    }

    private func recordToSave(for recordID: CKRecord.ID) -> CKRecord? {
        guard let identity = recordIdentity(from: recordID) else { return nil }

        let context = ModelContext(modelContainer)
        let record = stateStore.baseRecord(for: recordID, recordType: identity.type.rawValue)

        do {
            switch identity.type {
            case .scenario:
                guard let scenario = try fetchScenario(id: identity.id, context: context), scenario.presetID == nil else {
                    return nil
                }
                record["id"] = scenario.id.uuidString as NSString
                record["title"] = scenario.title as NSString
                record["callerName"] = scenario.callerName as NSString
                record["createdAt"] = scenario.createdAt as NSDate
                record["updatedAt"] = scenario.updatedAt as NSDate

            case .scriptLine:
                guard
                    let line = try fetchScriptLine(id: identity.id, context: context),
                    let scenarioID = line.scenario?.id
                else { return nil }
                record["id"] = line.id.uuidString as NSString
                record["scenarioID"] = scenarioID.uuidString as NSString
                record["text"] = line.text as NSString
                record["sortOrder"] = line.sortOrder as NSNumber
                record["isRecorded"] = line.isRecorded as NSNumber
                record["audioFileName"] = line.audioFileName as NSString?
                record["updatedAt"] = line.updatedAt as NSDate

            case .scenarioAudio:
                guard
                    let line = try fetchScriptLine(id: identity.id, context: context),
                    line.isRecorded,
                    let fileName = line.audioFileName
                else { return nil }
                let fileURL = try AudioFileManager.url(for: fileName)
                guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
                record["scriptLineID"] = line.id.uuidString as NSString
                record["fileName"] = fileName as NSString
                record["updatedAt"] = line.updatedAt as NSDate
                record["audio"] = CKAsset(fileURL: fileURL)

            case .safetyContact:
                guard let contact = try fetchSafetyContact(id: identity.id, context: context) else { return nil }
                record["id"] = contact.id.uuidString as NSString
                record["name"] = contact.name as NSString
                record["phoneNumber"] = contact.phoneNumber as NSString
                record["shouldShareLocation"] = contact.shouldShareLocation as NSNumber
                record["updatedAt"] = contact.updatedAt as NSDate
            }
            return record
        } catch {
            logger.error("Failed to build CloudKit record: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func applyFetchedChanges(_ changes: CKSyncEngine.Event.FetchedRecordZoneChanges) {
        let sortedRecords = changes.modifications.map(\.record).sorted {
            recordSortOrder($0.recordType) < recordSortOrder($1.recordType)
        }

        let context = ModelContext(modelContainer)
        do {
            for record in sortedRecords {
                try apply(record: record, context: context)
                stateStore.saveSystemFields(for: record)
            }
            for deletion in changes.deletions {
                try applyDeletion(
                    recordID: deletion.recordID,
                    recordType: deletion.recordType,
                    context: context
                )
            }
            try context.save()
        } catch {
            logger.error("Failed to apply fetched CloudKit changes: \(error.localizedDescription, privacy: .public)")
            status = .failed("iCloud에서 받은 데이터를 저장하지 못했습니다.")
        }
    }

    private func apply(record: CKRecord, context: ModelContext) throws {
        guard
            let type = CloudSyncRecordType(rawValue: record.recordType),
            let id = uuidField("id", in: record) ?? recordIdentity(from: record.recordID)?.id
        else { return }

        let remoteUpdatedAt = dateField("updatedAt", in: record) ?? record.modificationDate ?? .distantPast
        if let localChange = journal.pendingChanges().first(where: { $0.recordName == record.recordID.recordName }),
           localChange.operation == .save,
           localChange.changedAt > remoteUpdatedAt {
            return
        }

        switch type {
        case .scenario:
            let scenario = try fetchScenario(id: id, context: context) ?? Scenario(
                id: id,
                title: stringField("title", in: record) ?? "나의 통화",
                callerName: stringField("callerName", in: record) ?? "",
                createdAt: dateField("createdAt", in: record) ?? Date(),
                updatedAt: remoteUpdatedAt
            )
            if scenario.modelContext == nil { context.insert(scenario) }
            scenario.title = stringField("title", in: record) ?? scenario.title
            scenario.callerName = stringField("callerName", in: record) ?? scenario.callerName
            scenario.createdAt = dateField("createdAt", in: record) ?? scenario.createdAt
            scenario.updatedAt = remoteUpdatedAt

        case .scriptLine:
            guard
                let scenarioIDString = stringField("scenarioID", in: record),
                let scenarioID = UUID(uuidString: scenarioIDString),
                let scenario = try fetchScenario(id: scenarioID, context: context)
            else { return }

            let line = try fetchScriptLine(id: id, context: context) ?? ScriptLine(
                id: id,
                text: stringField("text", in: record) ?? "",
                sortOrder: intField("sortOrder", in: record) ?? scenario.scriptLines.count,
                updatedAt: remoteUpdatedAt,
                scenario: scenario
            )
            if line.modelContext == nil {
                scenario.scriptLines.append(line)
            }
            line.text = stringField("text", in: record) ?? line.text
            line.sortOrder = intField("sortOrder", in: record) ?? line.sortOrder
            line.isRecorded = boolField("isRecorded", in: record) ?? line.isRecorded
            line.audioFileName = stringField("audioFileName", in: record)
            line.scenario = scenario
            line.updatedAt = remoteUpdatedAt

        case .scenarioAudio:
            // CKAsset is copied immediately because CloudKit owns the staging URL.
            guard
                let line = try fetchScriptLine(id: id, context: context),
                let asset = record["audio"] as? CKAsset,
                let sourceURL = asset.fileURL
            else { return }
            let localFileName = "icloud-\(id.uuidString.lowercased()).m4a"
            let destinationURL = try AudioFileManager.url(for: localFileName)
            try? FileManager.default.removeItem(at: destinationURL)
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            line.audioFileName = localFileName
            line.isRecorded = true
            line.updatedAt = remoteUpdatedAt

        case .safetyContact:
            let contact = try fetchSafetyContact(id: id, context: context) ?? SafetyContact(
                id: id,
                name: stringField("name", in: record) ?? "",
                phoneNumber: stringField("phoneNumber", in: record) ?? "",
                shouldShareLocation: boolField("shouldShareLocation", in: record) ?? true,
                updatedAt: remoteUpdatedAt
            )
            if contact.modelContext == nil { context.insert(contact) }
            contact.name = stringField("name", in: record) ?? contact.name
            contact.phoneNumber = stringField("phoneNumber", in: record) ?? contact.phoneNumber
            contact.shouldShareLocation = boolField("shouldShareLocation", in: record) ?? contact.shouldShareLocation
            contact.updatedAt = remoteUpdatedAt
        }
    }

    private func applyDeletion(
        recordID: CKRecord.ID,
        recordType: CKRecord.RecordType,
        context: ModelContext
    ) throws {
        if journal.pendingChanges().contains(where: {
            $0.recordName == recordID.recordName && $0.operation == .save
        }) {
            return
        }

        guard
            let type = CloudSyncRecordType(rawValue: recordType),
            let identity = recordIdentity(from: recordID)
        else { return }

        switch type {
        case .scenario:
            if let scenario = try fetchScenario(id: identity.id, context: context) {
                for line in scenario.scriptLines {
                    try? AudioFileManager.deleteIfNeeded(fileName: line.audioFileName)
                }
                context.delete(scenario)
            }
        case .scriptLine:
            if let line = try fetchScriptLine(id: identity.id, context: context) {
                try? AudioFileManager.deleteIfNeeded(fileName: line.audioFileName)
                context.delete(line)
            }
        case .scenarioAudio:
            if let line = try fetchScriptLine(id: identity.id, context: context) {
                try? AudioFileManager.deleteIfNeeded(fileName: line.audioFileName)
                line.audioFileName = nil
                line.isRecorded = false
            }
        case .safetyContact:
            if let contact = try fetchSafetyContact(id: identity.id, context: context) {
                context.delete(contact)
            }
        }
        stateStore.removeSystemFields(for: [recordID.recordName])
    }

    private func handleSentRecordChanges(
        _ changes: CKSyncEngine.Event.SentRecordZoneChanges,
        syncEngine: CKSyncEngine
    ) {
        let currentChanges = Dictionary(
            uniqueKeysWithValues: journal.pendingChanges().map { ($0.recordName, $0) }
        )
        var completedNames = Set<String>()

        for record in changes.savedRecords {
            let recordName = record.recordID.recordName
            let sentUpdatedAt = dateField("updatedAt", in: record) ?? .distantPast
            if let current = currentChanges[recordName],
               current.operation == .save,
               current.changedAt <= sentUpdatedAt {
                completedNames.insert(recordName)
            }
        }

        for recordID in changes.deletedRecordIDs {
            if currentChanges[recordID.recordName]?.operation == .delete {
                completedNames.insert(recordID.recordName)
            }
        }

        changes.savedRecords.forEach(stateStore.saveSystemFields)
        stateStore.removeSystemFields(for: Set(changes.deletedRecordIDs.map(\.recordName)))

        for failedSave in changes.failedRecordSaves {
            let error = failedSave.error
            guard error.code == .serverRecordChanged,
                  let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord
            else { continue }

            let recordName = failedSave.record.recordID.recordName
            guard let currentChange = currentChanges[recordName], currentChange.operation == .save else {
                stateStore.saveSystemFields(for: serverRecord)
                continue
            }
            let localChangedAt = currentChange.changedAt
            let serverChangedAt = dateField("updatedAt", in: serverRecord)
                ?? serverRecord.modificationDate
                ?? .distantPast

            if serverChangedAt >= localChangedAt {
                let context = ModelContext(modelContainer)
                do {
                    try apply(record: serverRecord, context: context)
                    try context.save()
                    completedNames.insert(recordName)
                    syncEngine.state.remove(pendingRecordZoneChanges: [.saveRecord(failedSave.record.recordID)])
                } catch {
                    logger.error("Failed to resolve server conflict: \(error.localizedDescription, privacy: .public)")
                }
            } else {
                // Preserve the server change tag so the next client-wins retry can update it.
                stateStore.saveSystemFields(for: serverRecord)
            }
        }

        for (recordID, error) in changes.failedRecordDeletes where error.code == .unknownItem {
            if currentChanges[recordID.recordName]?.operation == .delete {
                completedNames.insert(recordID.recordName)
            }
            syncEngine.state.remove(pendingRecordZoneChanges: [.deleteRecord(recordID)])
        }

        journal.remove(recordNames: completedNames)
        // A second local edit can arrive while the first version is in flight.
        // CKSyncEngine removes the completed pending item, so re-add any newer
        // journal entry now instead of waiting for the next app launch.
        addJournalChangesToEngine()
    }

    private func handleSyncError(_ error: Error) {
        logger.error("Cloud sync failed: \(error.localizedDescription, privacy: .public)")
        if case CloudSyncError.accountUnavailable = error {
            status = .unavailable(error.localizedDescription)
        } else {
            status = .failed("iCloud 동기화에 실패했습니다. 잠시 후 다시 시도해 주세요.")
        }
    }

    private func fetchScenario(id: UUID, context: ModelContext) throws -> Scenario? {
        var descriptor = FetchDescriptor<Scenario>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchScriptLine(id: UUID, context: ModelContext) throws -> ScriptLine? {
        var descriptor = FetchDescriptor<ScriptLine>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchSafetyContact(id: UUID, context: ModelContext) throws -> SafetyContact? {
        var descriptor = FetchDescriptor<SafetyContact>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func recordIdentity(from recordID: CKRecord.ID) -> (type: CloudSyncRecordType, id: UUID)? {
        for type in [CloudSyncRecordType.scenario, .scriptLine, .scenarioAudio, .safetyContact] {
            let prefix = "\(type.rawValue)-"
            guard recordID.recordName.hasPrefix(prefix) else { continue }
            let value = String(recordID.recordName.dropFirst(prefix.count))
            if let id = UUID(uuidString: value) { return (type, id) }
        }
        return nil
    }

    private func recordSortOrder(_ type: String) -> Int {
        switch CloudSyncRecordType(rawValue: type) {
        case .scenario: 0
        case .scriptLine: 1
        case .scenarioAudio: 2
        case .safetyContact: 3
        case nil: 4
        }
    }

    private func stringField(_ key: String, in record: CKRecord) -> String? {
        record[key] as? String
    }

    private func uuidField(_ key: String, in record: CKRecord) -> UUID? {
        stringField(key, in: record).flatMap(UUID.init(uuidString:))
    }

    private func dateField(_ key: String, in record: CKRecord) -> Date? {
        record[key] as? Date
    }

    private func intField(_ key: String, in record: CKRecord) -> Int? {
        (record[key] as? NSNumber)?.intValue
    }

    private func boolField(_ key: String, in record: CKRecord) -> Bool? {
        (record[key] as? NSNumber)?.boolValue
    }
}

private enum CloudSyncError: LocalizedError {
    case accountUnavailable

    var errorDescription: String? {
        switch self {
        case .accountUnavailable:
            "이 기기에서 사용할 수 있는 iCloud 계정이 없습니다."
        }
    }
}

private final class CloudSyncEngineDelegateBridge: CKSyncEngineDelegate, @unchecked Sendable {
    weak var coordinator: CloudSyncCoordinator?

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        await coordinator?.handleEvent(event, syncEngine: syncEngine)
    }

    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        await coordinator?.nextRecordZoneChangeBatch(context: context, syncEngine: syncEngine)
    }
}

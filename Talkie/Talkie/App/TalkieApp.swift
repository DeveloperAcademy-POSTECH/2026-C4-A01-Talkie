//
//  TalkieApp.swift
//  Talkie
//
//  Created by DS on 7/9/26.
//

import SwiftUI
import SwiftData
import Observation
import OSLog

@main
struct TalkieApp: App {
    @State private var bootstrapStore = AppBootstrapStore()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let container = bootstrapStore.modelContainer,
                   let cloudSyncCoordinator = bootstrapStore.cloudSyncCoordinator {
                    rootView
                        .modelContainer(container)
                        .environment(cloudSyncCoordinator)
                        .task(priority: .background) {
                            await bootstrapStore.migrateLegacyPresetDataIfNeeded()
                            cloudSyncCoordinator.startIfNeeded()
                        }
                } else if let launchErrorMessage = bootstrapStore.launchErrorMessage {
                    ContentUnavailableView(
                        "앱을 시작할 수 없습니다",
                        systemImage: "exclamationmark.triangle",
                        description: Text(launchErrorMessage)
                    )
                } else {
                    SplashView()
                        .task(priority: .userInitiated) {
                            await bootstrapStore.prepareAppDependencies()
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
#if DEBUG
        if let screenshotMode = ReleaseScreenshotMode.current {
            // App Store 스크린샷은 실제 제품 화면을 그대로 사용하되, 권한 팝업이나
            // 사용자 데이터에 영향받지 않는 결정적인 상태로 실행합니다.
            ReleaseScreenshotView(mode: screenshotMode)
        } else {
            appMainView
        }
#else
        appMainView
#endif
    }

    private var appMainView: some View {
        AppMainView()
    }
}

@MainActor
@Observable
private final class AppBootstrapStore {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Talkie",
        category: "AppBootstrap"
    )
    private static let legacyPresetMigrationKey = "hasMigratedLegacyPresetData"

    private(set) var modelContainer: ModelContainer?
    private(set) var cloudSyncCoordinator: CloudSyncCoordinator?
    private(set) var launchErrorMessage: String?

    private var isPreparingAppDependencies = false
    private var isMigratingLegacyPresetData = false

    func prepareAppDependencies() async {
        guard !isPreparingAppDependencies, modelContainer == nil else { return }
        isPreparingAppDependencies = true

        do {
            let container = try await Task.detached(priority: .userInitiated) {
                try Self.makeModelContainer()
            }.value

            // Observable UI 상태와 @MainActor 서비스 생성은 MainActor에서만 수행합니다.
            modelContainer = container
            cloudSyncCoordinator = CloudSyncCoordinator(modelContainer: container)
        } catch {
            Self.logger.fault("ModelContainer 생성 실패: \(String(reflecting: error), privacy: .public)")
            launchErrorMessage = "데이터 저장소를 준비하지 못했습니다. 앱을 다시 실행해 주세요."
        }
    }

    func migrateLegacyPresetDataIfNeeded() async {
        guard !isMigratingLegacyPresetData,
              !UserDefaults.standard.bool(forKey: Self.legacyPresetMigrationKey),
              let modelContainer else {
            return
        }
        isMigratingLegacyPresetData = true
        defer { isMigratingLegacyPresetData = false }

        do {
            let migrationActor = ScenarioMigrationActor(modelContainer: modelContainer)
            try await migrationActor.migrateLegacyPresetData()
            UserDefaults.standard.set(true, forKey: Self.legacyPresetMigrationKey)
        } catch {
            // 마이그레이션 실패는 다음 실행에서 재시도하되 현재 앱 시작은 막지 않습니다.
            Self.logger.error("기존 프리셋 데이터 마이그레이션 실패: \(String(reflecting: error), privacy: .public)")
        }
    }

    nonisolated private static func makeModelContainer() throws -> ModelContainer {
        // CKSyncEngine이 동기화를 전담하므로 SwiftData 자동 CloudKit store는 끕니다.
        let configuration = ModelConfiguration(cloudKitDatabase: .none)
        return try ModelContainer(
            for: Scenario.self,
            ScriptLine.self,
            AudioClipMetadata.self,
            SafetyContact.self,
            CallSession.self,
            CallRecording.self,
            configurations: configuration
        )
    }
}

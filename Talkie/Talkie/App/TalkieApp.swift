//
//  TalkieApp.swift
//  Talkie
//
//  Created by DS on 7/9/26.
//

import SwiftUI
import SwiftData

@main
struct TalkieApp: App {
    let container: ModelContainer
    let cloudSyncCoordinator: CloudSyncCoordinator
    
    init() {
        do {
            container = try ModelContainer(
                for: Scenario.self,
                ScriptLine.self,
                AudioClipMetadata.self,
                SafetyContact.self,
                CallSession.self,
                CallRecording.self
            )
        } catch {
            fatalError("ModelContainer 생성 실패: \(String(reflecting: error))")
        }

        cloudSyncCoordinator = CloudSyncCoordinator(modelContainer: container)
        
        do {
            try ScenarioSeedService.migrateLegacyPresetDataIfNeeded(
                into: ModelContext(container)
            )
        } catch {
            fatalError("기존 프리셋 데이터 마이그레이션 실패: \(String(reflecting: error))")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppMainView()
                .environment(cloudSyncCoordinator)
                .task {
                    cloudSyncCoordinator.startIfNeeded()
                }
        }
        .modelContainer(container)
    }
}

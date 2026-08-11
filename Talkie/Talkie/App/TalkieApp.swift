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
            // Talkie는 SwiftData가 제공하는 자동 CloudKit 동기화가 아니라
            // CloudSyncCoordinator의 CKSyncEngine으로 동기화 범위와 충돌 처리를 관리한다.
            // iCloud entitlement가 있을 때 SwiftData의 기본값(.automatic)이 별도의
            // CloudKit store를 활성화하지 않도록 관리형 동기화를 명시적으로 끈다.
            let configuration = ModelConfiguration(cloudKitDatabase: .none)

            container = try ModelContainer(
                for: Scenario.self,
                ScriptLine.self,
                AudioClipMetadata.self,
                SafetyContact.self,
                CallSession.self,
                CallRecording.self,
                configurations: configuration
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
            rootView
        }
        .modelContainer(container)
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
            .environment(cloudSyncCoordinator)
            .task {
                cloudSyncCoordinator.startIfNeeded()
            }
    }
}

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
    
    init() {
        do {
            container = try ModelContainer(
                for: Scenario.self,
                CallerProfile.self,
                ScriptLine.self,
                AudioClipMetadata.self,
                CallReservation.self,
                SafetyContact.self
            )
        } catch {
            fatalError("ModelContainer 생성 실패: \(String(reflecting: error))")
        }
        
        do {
            try ScenarioSeedService.insertDefaultScenariosIfNeeded(
                into: ModelContext(container)
            )
        } catch {
            fatalError("기본 시나리오 seed 실패: \(String(reflecting: error))")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppMainView()
        }
        .modelContainer(container)
    }
}

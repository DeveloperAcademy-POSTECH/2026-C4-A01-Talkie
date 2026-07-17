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
                EmergencyContact.self
            )
            
            try ScenarioSeedService.insertDefaultScenariosIfNeeded(
                into: ModelContext(container)
            )
        } catch {
            fatalError("ModelContainer 초기화 실패: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}

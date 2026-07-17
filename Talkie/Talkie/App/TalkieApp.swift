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
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [
            Scenario.self,
            CallerProfile.self,
            ScriptLine.self,
            AudioClipMetadata.self,
            CallReservation.self,
            EmergencyContact.self
        ])
    }
}

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
    
    init(){
        do {
            container = try ModelContainer(for: CallerProfile.self, ScriptLine.self, EmergencyContact.self, AudioClipMetadata.self)
        } catch {
            fatalError("ModelContainer 초기화 실패: \(error.localizedDescription)")
        }
    }
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
        }
        .modelContainer(container) // 앱 전체에서 CallerProfile을 저장 및 불러오기
    }
}

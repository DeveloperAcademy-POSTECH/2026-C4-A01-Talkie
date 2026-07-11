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
    init() {
        IncomingCallRingtoneService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
        }
        .modelContainer(for: CallerProfile.self) // 앱 전체에서 CallerProfile을 저장 및 불러오기
    }
}

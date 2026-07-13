//
//  ContentView.swift
//  Talkie
//
//  Created by DS on 7/9/26.
//

import SwiftUI
import SwiftData

struct AppCoordinatorView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Query private var scenarios: [Scenario]
    
    var body: some View {
        if scenarios.isEmpty {
            CallerProfileSetupView()
        } else {
            HomeView()
        }
    }
}

//#Preview {
//    AppCoordinatorView()
//}

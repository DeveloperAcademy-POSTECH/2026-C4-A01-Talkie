//
//  AppMainView.swift
//  Talkie
//
//  Created by DS on 7/20/26.
//

import SwiftUI

enum AppLaunchState {
    case splash
    case onboarding
    case main
}

struct AppMainView: View {
    @AppStorage("isFirstLaunch")
    private var isFirstLaunch = true
    
    @State private var launchState: AppLaunchState = .splash
    
    var body: some View {
        Group {
            switch launchState {
            case .splash:
                SplashView()
                    .task {
                        await finishSplash()
                    }
            case .onboarding:
                OnboardingView {
                    finishOnboarding()
                }
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut, value: launchState)
    }
    
    private func finishSplash() async {
        try? await Task.sleep(for: .seconds(1.5))
        
        await MainActor.run {
            withAnimation {
                launchState = isFirstLaunch ? .onboarding : .main
            }
        }
    }
    
    private func finishOnboarding() {
        isFirstLaunch = false
        
        withAnimation {
            launchState = .main
        }
    }
}

#Preview {
    AppMainView()
}

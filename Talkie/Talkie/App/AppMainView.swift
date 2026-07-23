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
    case safetyContactSetup
    case main
}

struct AppMainView: View {
    @AppStorage("isFirstLaunch")
    private var isFirstLaunch = true
    
    @AppStorage("hasCompletedSafetyContactSetup")
    private var hasCompletedSafetyContactSetup = false

    @AppStorage(TalkiePreferenceKey.widgetCallRequestID)
    private var widgetCallRequestID = ""
    
    @State private var launchState: AppLaunchState = .splash
    
    var body: some View {
        DarkScreen {
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
                case .safetyContactSetup:
                    SafetyContactSetupView {
                        finishSafetyContactSetup()
                    }
                case .main:
                    MainTabView()
                }
            }
        }
        .animation(.easeInOut, value: launchState)
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }
    
    private func finishSplash() async {
        try? await Task.sleep(for: .seconds(1.5))
        
        await MainActor.run {
            withAnimation {
                if isFirstLaunch {
                    launchState = .onboarding
                } else if !hasCompletedSafetyContactSetup {
                    launchState = .safetyContactSetup
                } else {
                    launchState = .main
                }
            }
        }
    }
    
    private func finishOnboarding() {
        withAnimation {
            launchState = .safetyContactSetup
        }
    }
    
    private func finishSafetyContactSetup() {
        isFirstLaunch = false
        hasCompletedSafetyContactSetup = true
        
        withAnimation {
            launchState = .main
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "myapp",
              url.host == "call" else {
            return
        }

        widgetCallRequestID = UUID().uuidString

        guard !isFirstLaunch,
              hasCompletedSafetyContactSetup else {
            return
        }

        withAnimation {
            launchState = .main
        }
    }
}

#Preview {
    AppMainView()
}

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
    @State private var hasPreparedLaunch = false
    
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
        // 분기 화면이 바뀌어도 유지되는 루트 수명에 연결해 위젯 딥링크가 splash를
        // 건너뛰는 경우에도 고아 Live Activity 정리가 취소되지 않게 합니다.
        .task {
            await prepareLaunch()
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    /// 강제 종료나 크래시 뒤 시스템에 남은 Live Activity는 새 프로세스가 시작될 때 정리합니다.
    /// 프로세스가 이미 종료된 정확한 순간에는 앱 코드를 실행할 수 없으므로, 다음 실행이
    /// 로컬 ActivityKit만 사용하는 현재 구조에서 보장할 수 있는 가장 빠른 복구 시점입니다.
    private func prepareLaunch() async {
        guard !hasPreparedLaunch else { return }
        hasPreparedLaunch = true
        await FakeCallLiveActivityManager.shared.end()
        await finishSplash()
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

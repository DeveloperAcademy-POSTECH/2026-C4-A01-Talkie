#if DEBUG
import SwiftUI

/// Fastlane이 제품 화면을 동일한 데이터와 상태로 반복 촬영하기 위한 Debug 전용 진입점입니다.
///
/// `xcrun simctl launch ... -talkieScreenshotMode phoneHome`처럼 실행하면
/// 온보딩, 권한 팝업, iCloud 상태와 무관하게 지정한 화면을 바로 표시합니다.
/// Release 빌드에는 이 분기와 화면이 포함되지 않습니다.
enum ReleaseScreenshotMode: String {
    case phoneHome
    case activeCall
    case sos
    case scenarioList
    case onboardingSafety

    static var current: ReleaseScreenshotMode? {
        guard let rawValue = UserDefaults.standard.string(
            forKey: "talkieScreenshotMode"
        ) else {
            return nil
        }

        return ReleaseScreenshotMode(rawValue: rawValue)
    }
}

struct ReleaseScreenshotView: View {
    let mode: ReleaseScreenshotMode

    var body: some View {
        switch mode {
        case .phoneHome:
            NavigationStack {
                PhoneHomeContentView(
                    scenario: PresetScenarioCatalog.kevin.content,
                    isWidgetInstalled: false,
                    onChangeScenario: {},
                    onStartCall: {}
                )
            }

        case .activeCall:
            ActiveFakeCallView(
                profile: screenshotProfile,
                callStartedAt: .now.addingTimeInterval(-43),
                phase: .waitingForUser,
                currentInputLevel: -42,
                voiceMonitoringState: .listening,
                isSpeakerEnabled: true,
                onEndCall: {},
                onSkipLine: {},
                onSpeakerChange: { _ in },
                onShareLocation: {},
                onEmergencySMS: {},
                onEmergencyCall: {}
            )

        case .sos:
            SOSView()

        case .scenarioList:
            ScenarioView()

        case .onboardingSafety:
            onboardingSafetyPage
        }
    }

    private var onboardingSafetyPage: some View {
        DarkScreen {
            VStack(spacing: 0) {
                OnboardingPageView(data: OnboardingData.pages[2])

                OnboardingPageIndicator(
                    pageCount: OnboardingData.pages.count,
                    selectedIndex: 2
                )
                .padding(.bottom, 102)
            }
        }
    }

    private var screenshotProfile: VirtualCallerProfile {
        VirtualCallerProfile(
            id: UUID(uuidString: "8E37F9D5-1F34-4882-96C6-9B85F4A80F11")!,
            displayName: "Kevin",
            relationship: "휴대전화",
            imageSystemName: "person.crop.circle.fill"
        )
    }
}
#endif

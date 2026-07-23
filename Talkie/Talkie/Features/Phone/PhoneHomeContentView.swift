//
//  PhoneHomeContentView.swift
//  Talkie
//

import SwiftUI

/// 통화 탭의 정적인 화면 구성을 담당합니다.
///
/// 시나리오 선택이나 통화 시작 같은 상태 변경은 소유하지 않고 사용자 입력을
/// callback으로 전달해 `PhoneView`가 화면 흐름을 조정하도록 합니다.
struct PhoneHomeContentView: View {
    let scenario: ScenarioContent
    let isWidgetInstalled: Bool
    let onChangeScenario: () -> Void
    let onStartCall: () -> Void

    var body: some View {
        DarkScreen {
            VStack(alignment: .leading, spacing: 0) {
                MainTabHeader(title: "대화 선택") {
                    NavigationLink {
                        MyPageView()
                    } label: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Constants.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("마이페이지")
                }

                if !isWidgetInstalled {
                    NavigationLink {
                        WidgetInstallUI()
                    } label: {
                        WidgetInstallBannerView()
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 12)
                }

                VStack(spacing: 20) {
                    PhoneCardView(
                        scenario: scenario,
                        onChangeScenario: onChangeScenario
                    )

                    StartFakeCallButton(action: onStartCall)
                }
                .padding(.horizontal, 24)
                .padding(.top, isWidgetInstalled ? 52 : 32)

                Spacer()
            }
        }
    }
}

private struct StartFakeCallButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16, weight: .bold))

                Text("전화하기")
                    .font(.pretendard(.bold, size: 16))
            }
            .foregroundStyle(Color.green)
            .padding(.horizontal, 10)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Constants.grey700)
            .cornerRadius(100)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("가상 통화 시작")
    }
}

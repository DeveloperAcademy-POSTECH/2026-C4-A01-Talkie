//
//  FakeCallPresentationView.swift
//  Talkie
//

import SwiftUI

/// 통화 coordinator의 phase를 실제 전체 화면 통화 UI로 변환합니다.
/// 명시적인 observation 경계를 제공해 coordinator 상태 변경이 presentation에 반영됩니다.
struct FakeCallPresentationView: View {
    @Bindable var coordinator: FakeCallCoordinator

    let onAccept: () -> Void
    let onDecline: () -> Void
    let onEndCall: () -> Void
    let onShareLocation: () -> Void
    let onEmergencySMS: () -> Void
    let onEmergencyCall: () -> Void

    var body: some View {
        Group {
            if coordinator.phase == .incoming,
               let profile = coordinator.profile {
                IncomingFakeCallView(
                    profile: profile,
                    onAccept: onAccept,
                    onDecline: onDecline
                )
            } else if coordinator.phase.isActiveCall,
                      let profile = coordinator.profile,
                      let callStartedAt = coordinator.callStartedAt {
                ActiveFakeCallView(
                    profile: profile,
                    callStartedAt: callStartedAt,
                    phase: coordinator.phase,
                    currentInputLevel: coordinator.currentInputLevel,
                    voiceMonitoringState: coordinator.voiceMonitoringState,
                    isSpeakerEnabled: coordinator.isSpeakerEnabled,
                    onEndCall: onEndCall,
                    onSkipLine: coordinator.skipToNextLine,
                    onSpeakerChange: coordinator.setSpeakerEnabled,
                    onShareLocation: onShareLocation,
                    onEmergencySMS: onEmergencySMS,
                    onEmergencyCall: onEmergencyCall
                )
            } else if case let .failed(message) = coordinator.phase {
                FailedFakeCallView(message: message, onEndCall: onEndCall)
            } else {
                PreparingFakeCallView()
            }
        }
    }
}

private struct PreparingFakeCallView: View {
    var body: some View {
        ZStack {
            CallScreenBackground()
                .ignoresSafeArea()

            ProgressView()
                .tint(.white)
                .accessibilityLabel("가상 통화 준비 중")
        }
        .preferredColorScheme(.dark)
    }
}

private struct FailedFakeCallView: View {
    let message: String
    let onEndCall: () -> Void

    var body: some View {
        ZStack {
            CallScreenBackground()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(message)
                    .font(.pretendard(.semiBold, size: 17))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Button("돌아가기", action: onEndCall)
                    .buttonStyle(.borderedProminent)
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
    }
}

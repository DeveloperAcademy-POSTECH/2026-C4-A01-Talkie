//
//  ActiveFakeCallView.swift
//  Talkie
//

import SwiftUI

struct ActiveFakeCallView: View {
    let profile: VirtualCallerProfile
    let callStartedAt: Date
    let phase: FakeCallPhase
    let currentInputLevel: Double
    let voiceMonitoringState: VoiceMonitoringState
    let isSpeakerEnabled: Bool
    let onEndCall: () -> Void
    let onSkipLine: () -> Void
    let onSpeakerChange: (Bool) -> Void
    let onShareLocation: () -> Void
    let onEmergencySMS: () -> Void
    let onEmergencyCall: () -> Void

    @State private var isMuted = false

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 18),
        count: 3
    )

    var body: some View {
        ZStack {
            CallScreenBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                callerHeader
                    .padding(.top, 52)

                Spacer(minLength: 24)

                controls
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 520)
        }
        .preferredColorScheme(.dark)
        .accessibilityAction(named: "다음 문장 재생", onSkipLine)
    }

    private var callerHeader: some View {
        HStack(spacing: 14) {
            ActiveCallerAvatar(systemImageName: profile.imageSystemName)

            VStack(alignment: .leading, spacing: 2) {
                TimelineView(.periodic(from: callStartedAt, by: 1)) { context in
                    Text(callDuration(at: context.date))
                        .font(Font.pretendard(.medium, size: 22).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.58))
                        .contentTransition(.numericText())
                        .onLongPressGesture(minimumDuration: 1) {
                            onSkipLine()
                        }
                        .accessibilityLabel("통화 시간 \(callDuration(at: context.date))")
                }

                Text(profile.displayName)
                    .font(.pretendard(.bold, size: 34))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // 발화 감지와 입력 레벨은 통화 진행에 계속 사용하지만 실제 전화 화면에는 표시하지 않습니다.
    private var controls: some View {
        LazyVGrid(columns: columns, spacing: 28) {
            ActiveCallControlButton(
                title: "스피커",
                icon: .system("speaker.wave.3.fill"),
                isSelected: isSpeakerEnabled,
                reportsSelectionState: true
            ) {
                onSpeakerChange(!isSpeakerEnabled)
            }

            ActiveCallControlButton(
                title: "메세지 신고",
                icon: .faceTime,
                accessibilityName: "112 문자 신고",
                accessibilityHint: "현재 가상 통화를 종료하고 위치가 포함된 112 문자 작성 화면을 엽니다.",
                action: onEmergencySMS
            )

            ActiveCallControlButton(
                title: "소리 끔",
                icon: .system(isMuted ? "mic.fill" : "mic.slash.fill"),
                isSelected: isMuted,
                reportsSelectionState: true
            ) {
                isMuted.toggle()
            }

            ActiveCallControlButton(
                title: "위치 공유",
                icon: .system("ellipsis"),
                accessibilityName: "안전 연락망에 위치 공유",
                accessibilityHint: "현재 가상 통화를 종료하고 저장된 안전 연락망에 위치 공유 문자를 준비합니다.",
                action: onShareLocation
            )

            ActiveCallControlButton(
                title: "종료",
                icon: .system("phone.down.fill"),
                backgroundColor: Color(red: 0.93, green: 0.17, blue: 0.21),
                action: onEndCall
            )

            ActiveCallControlButton(
                title: "전화 신고",
                icon: .system("circle.grid.3x3.fill"),
                accessibilityName: "112 전화 신고",
                accessibilityHint: "현재 가상 통화를 종료하고 112 전화 연결을 준비합니다.",
                action: onEmergencyCall
            )
        }
    }

    private func callDuration(at date: Date) -> String {
        let elapsed = max(0, Int(date.timeIntervalSince(callStartedAt)))
        return String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
    }
}

private struct ActiveCallerAvatar: View {
    let systemImageName: String?

    var body: some View {
        Image(systemName: systemImageName ?? "person.crop.circle.fill")
            .resizable()
            .scaledToFill()
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.white.opacity(0.9))
            .frame(width: 64, height: 64)
            .background(.white.opacity(0.12), in: Circle())
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.16), lineWidth: 0.5)
            }
            .accessibilityHidden(true)
    }
}

private enum ActiveCallControlIcon {
    case system(String)
    case faceTime
}

private struct ActiveCallControlButton: View {
    let title: String
    let icon: ActiveCallControlIcon
    var isSelected = false
    var isEnabled = true
    var backgroundColor: Color?
    var accessibilityName: String?
    var accessibilityHint: String?
    var reportsSelectionState = false
    let action: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            Button(action: action) {
                iconView
                    .foregroundStyle(isSelected ? .black : .white)
                    .frame(width: 80, height: 80)
                    .background(circleBackground, in: Circle())
                    .overlay {
                        if backgroundColor == nil && !isSelected {
                            Circle()
                                .stroke(.white.opacity(0.52), lineWidth: 1)
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .opacity(1)

            Text(title)
                .font(.pretendard(.regular, size: 17))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityName ?? title)
        .accessibilityValue(
            reportsSelectionState ? (isSelected ? "켬" : "끔") : ""
        )
        .accessibilityHint(accessibilityHint ?? "")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case let .system(name):
            Image(systemName: name)
                .font(.system(size: 30, weight: .semibold))

        case .faceTime:
            ZStack {
                Image(systemName: "video.fill")
                    .font(.system(size: 30, weight: .semibold))

                Text("?")
                    .font(.pretendard(.bold, size: 12))
                    .foregroundStyle(Color.black.opacity(0.7))
                    .offset(x: -4)
            }
        }
    }

    private var circleBackground: Color {
        if let backgroundColor {
            return backgroundColor
        }

        return isSelected ? .white : .white.opacity(0.12)
    }
}

#Preview("Active call") {
    ActiveFakeCallView(
        profile: .preview,
        callStartedAt: .now.addingTimeInterval(-43),
        phase: .waitingForUser,
        currentInputLevel: -42,
        voiceMonitoringState: .listening,
        isSpeakerEnabled: false,
        onEndCall: {},
        onSkipLine: {},
        onSpeakerChange: { _ in },
        onShareLocation: {},
        onEmergencySMS: {},
        onEmergencyCall: {}
    )
}

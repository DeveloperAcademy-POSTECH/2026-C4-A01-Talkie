//
//  ActiveFakeCallView.swift
//  Talkie
//


import SwiftUI

struct ActiveFakeCallView: View {
    let profile: VirtualCallerProfile
    let callStartedAt: Date
    let phase: FakeCallPhase
    let speechThreshold: Double
    let isSpeakerEnabled: Bool
    let onEndCall: () -> Void
    let onSkipLine: () -> Void
    let onSpeechThresholdChange: (Double) -> Void
    let onSpeakerChange: (Bool) -> Void

    @State private var isMuted = false

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 18),
        count: 3
    )

    var body: some View {
        ZStack {
            CallScreenBackground()

            VStack(spacing: 0) {
                callerHeader
                    .padding(.top, 58)

                Spacer(minLength: 18)

                sensitivityControl

                Spacer(minLength: 18)

                controls

                Spacer(minLength: 20)

                endCallButton
                    .padding(.bottom, 46)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 520)
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .accessibilityAction(named: "다음 문장 재생", onSkipLine)
    }

    private var sensitivityControl: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Label("발화 민감도", systemImage: "waveform")
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 8)

                Text("\(Int(speechThreshold.rounded())) dB")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            }

            Slider(
                value: Binding(
                    get: { speechThreshold },
                    set: onSpeechThresholdChange
                ),
                in: FakeCallCoordinator.speechThresholdRange,
                step: 1
            )
            .tint(.white)
            .accessibilityLabel("발화 감지 임계값")
            .accessibilityValue("\(Int(speechThreshold.rounded())) 데시벨")
            .accessibilityHint("값을 낮추면 작은 목소리에도 반응합니다")

            HStack {
                Text("작은 소리")
                Spacer()
                Text("큰 소리")
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.68))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
    }

    private var callerHeader: some View {
        VStack(spacing: 8) {
            Text(profile.displayName)
                .font(.system(size: 34, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            TimelineView(.periodic(from: callStartedAt, by: 1)) { context in
                Text(callDuration(at: context.date))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.74))
                    .contentTransition(.numericText())
                    .onLongPressGesture(minimumDuration: 1) {
                        onSkipLine()
                    }
                    .accessibilityLabel("통화 시간 \(callDuration(at: context.date))")
            }
        }
        .foregroundStyle(.white)
    }

    private var controls: some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ActiveCallControlButton(
                title: "소리 끔",
                systemImage: isMuted ? "mic.slash.fill" : "mic.fill",
                isSelected: isMuted
            ) {
                isMuted.toggle()
            }

            ActiveCallControlButton(
                title: "키패드",
                systemImage: "circle.grid.3x3.fill",
                isEnabled: false,
                action: {}
            )

            ActiveCallControlButton(
                title: "스피커",
                systemImage: "speaker.wave.3.fill",
                isSelected: isSpeakerEnabled
            ) {
                onSpeakerChange(!isSpeakerEnabled)
            }

            ActiveCallControlButton(
                title: "통화 추가",
                systemImage: "plus",
                isEnabled: false,
                action: {}
            )

            ActiveCallControlButton(
                title: "FaceTime",
                systemImage: "video.fill",
                isEnabled: false,
                action: {}
            )

            ActiveCallControlButton(
                title: "연락처",
                systemImage: "person.crop.circle",
                isEnabled: false,
                action: {}
            )
        }
    }

    private var endCallButton: some View {
        Button(action: onEndCall) {
            Image(systemName: "phone.down.fill")
                .font(.system(size: 31, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(
                    Color(red: 0.93, green: 0.17, blue: 0.21),
                    in: Circle()
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("통화 종료")
        .accessibilityHint("가상 통화를 종료합니다")
    }

    private func callDuration(at date: Date) -> String {
        let elapsed = max(0, Int(date.timeIntervalSince(callStartedAt)))
        return String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
    }
}

private struct ActiveCallControlButton: View {
    let title: String
    let systemImage: String
    var isSelected = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: 27, weight: .medium))
                    .foregroundStyle(isSelected ? .black : .white)
                    .frame(width: 72, height: 72)
                    .background(
                        isSelected ? Color.white : Color.white.opacity(0.18),
                        in: Circle()
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)

            Text(title)
                .font(.footnote)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "켬" : "끔")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Active call") {
    ActiveFakeCallView(
        profile: .preview,
        callStartedAt: .now.addingTimeInterval(-43),
        phase: .waitingForUser,
        speechThreshold: -35,
        isSpeakerEnabled: false,
        onEndCall: {},
        onSkipLine: {},
        onSpeechThresholdChange: { _ in },
        onSpeakerChange: { _ in }
    )
}

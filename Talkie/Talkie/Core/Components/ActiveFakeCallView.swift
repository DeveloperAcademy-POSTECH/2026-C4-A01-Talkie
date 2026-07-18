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

                voiceActivityStatus

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

    /// SpeechDetector의 상태와 마이크 입력 크기를 보여 주는 진단성 UI.
    /// 레벨 막대의 dB는 사용자가 마이크 동작 여부를 확인하기 위한 값이며,
    /// 색상 전환은 dB 임계값이 아니라 coordinator의 SpeechDetector 상태를 따른다.
    private var voiceActivityStatus: some View {
        VStack(spacing: 8) {
            monitoringStatus

            inputLevelMeter
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
    }

    private var monitoringStatus: some View {
        HStack(spacing: 8) {
            Label(monitoringStatusText, systemImage: monitoringStatusIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 8)

            if voiceMonitoringState == .listening
                || voiceMonitoringState == .speechDetected {
                Text("입력 \(Int(currentInputLevel.rounded())) dB")
                    .monospacedDigit()
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(monitoringStatusColor)
        .accessibilityElement(children: .combine)
    }

    private var inputLevelMeter: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.16))

                Capsule()
                    .fill(
                        voiceMonitoringState == .speechDetected
                            ? Color.green
                            : Color.white.opacity(0.72)
                    )
                    .frame(width: width * inputLevelFraction)
            }
        }
        .frame(height: 14)
        .accessibilityLabel("마이크 입력 레벨")
        .accessibilityValue(
            "입력 \(Int(currentInputLevel.rounded())) 데시벨"
        )
    }

    private var monitoringStatusText: String {
        if case .playingLine = phase {
            return "상대 음성 재생 중"
        }

        if phase == .waitingForNextLine {
            return "무음 감지됨"
        }

        if phase == .completed {
            return "통화 완료"
        }

        switch voiceMonitoringState {
        case .inactive:
            return "발화 감지 준비 중"
        case .listening:
            return "발화 대기"
        case .speechDetected:
            return "발화 감지됨"
        case .unavailable:
            return "마이크 감지 사용 불가"
        }
    }

    private var monitoringStatusIcon: String {
        if case .playingLine = phase {
            return "waveform"
        }

        switch voiceMonitoringState {
        case .inactive:
            return "pause.fill"
        case .listening:
            return "mic.fill"
        case .speechDetected:
            return "waveform"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        }
    }

    private var monitoringStatusColor: Color {
        if case .playingLine = phase {
            return .white.opacity(0.78)
        }

        switch voiceMonitoringState {
        case .speechDetected:
            return .green
        case .unavailable:
            return .yellow
        case .inactive, .listening:
            return .white.opacity(0.78)
        }
    }

    private var inputLevelFraction: Double {
        min(max((currentInputLevel + 80) / 80, 0), 1)
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
        currentInputLevel: -42,
        voiceMonitoringState: .listening,
        isSpeakerEnabled: false,
        onEndCall: {},
        onSkipLine: {},
        onSpeakerChange: { _ in }
    )
}

//
//  FakeCallEntryView.swift
//  Talkie
//


import Foundation
import SwiftUI

struct FakeCallEntryView: View {
    private enum Screen: Equatable {
        case launcher
        case incoming
        case activeCall
    }

    private let startsImmediately: Bool
    private let onCallEnded: (() -> Void)?

    @State private var coordinator: FakeCallCoordinator

    init(
        repository: (any FakeCallScriptRepository)? = nil,
        startsImmediately: Bool = false,
        onCallEnded: (() -> Void)? = nil
    ) {
        self.startsImmediately = startsImmediately
        self.onCallEnded = onCallEnded
        _coordinator = State(initialValue: FakeCallCoordinator(repository: repository))
    }

    init(
        coordinator: FakeCallCoordinator,
        startsImmediately: Bool = false,
        onCallEnded: (() -> Void)? = nil
    ) {
        self.startsImmediately = startsImmediately
        self.onCallEnded = onCallEnded
        _coordinator = State(initialValue: coordinator)
    }

    var body: some View {
        Group {
            switch screen {
            case .launcher:
                launcher

            case .incoming:
                if let profile = coordinator.profile {
                    IncomingFakeCallView(
                        profile: profile,
                        onAccept: coordinator.acceptCall,
                        onDecline: finishDeclinedCall
                    )
                }

            case .activeCall:
                if let profile = coordinator.profile,
                   let callStartedAt = coordinator.callStartedAt {
                    ActiveFakeCallView(
                        profile: profile,
                        callStartedAt: callStartedAt,
                        phase: coordinator.phase,
                        speechThreshold: coordinator.speechThreshold,
                        isSpeakerEnabled: coordinator.isSpeakerEnabled,
                        onEndCall: finishActiveCall,
                        onSkipLine: coordinator.skipToNextLine,
                        onSpeechThresholdChange: coordinator.updateSpeechThreshold,
                        onSpeakerChange: coordinator.setSpeakerEnabled
                    )
                }
            }
        }
        .task {
            if startsImmediately, coordinator.phase == .idle {
                coordinator.startIncomingCall()
            }

            #if DEBUG
            await runDebugLaunchScenarioIfNeeded()
            #endif
        }
    }

    private func finishDeclinedCall() {
        coordinator.declineCall()
        onCallEnded?()
    }

    private func finishActiveCall() {
        coordinator.endCall()
        onCallEnded?()
    }

    private var screen: Screen {
        if coordinator.phase == .incoming {
            return .incoming
        }

        if coordinator.phase.isActiveCall {
            return .activeCall
        }

        return .launcher
    }

    private var launcher: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "phone.arrow.up.right.fill")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 112, height: 112)
                    .background(Color.accentColor, in: Circle())
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("가상 통화")
                        .font(.largeTitle.bold())

                    Text("엄마 · 문장 3개")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                if case let .failed(message) = coordinator.phase {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("오류. \(message)")
                }

                Spacer()

                Button {
                    coordinator.startIncomingCall()
                } label: {
                    if coordinator.phase == .loading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("지금 테스트", systemImage: "phone.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(coordinator.phase == .loading)
                .accessibilityHint("가상 전화 수신 화면을 엽니다")
            }
            .padding(24)
            .navigationTitle("가상 통화 테스트")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    #if DEBUG
    private func runDebugLaunchScenarioIfNeeded() async {
        let arguments = ProcessInfo.processInfo.arguments
        let shouldAutoAccept = arguments.contains("--fake-call-auto-accept")
        let shouldAutoStart = shouldAutoAccept || arguments.contains("--fake-call-auto-start")

        guard shouldAutoStart, coordinator.phase == .idle else { return }

        coordinator.startIncomingCall()

        while coordinator.phase == .loading {
            try? await Task.sleep(for: .milliseconds(50))
        }

        if shouldAutoAccept, coordinator.phase == .incoming {
            coordinator.acceptCall()
        }
    }
    #endif
}

#Preview("FakeCall launcher") {
    FakeCallEntryView()
}

//
//  FakeCallView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI
import SwiftData

struct PhoneView: View {
    @State private var isFakeCallPresented = false
    @State private var isMyPagePresented = false
    @State private var fakeCallCoordinator = FakeCallCoordinator()

    @Query(
        filter: #Predicate<Scenario> { scenario in
            scenario.isCurrentSelection == true
        },
        sort: \Scenario.createdAt,
        order: .reverse
    )
    private var currentScenarios: [Scenario]
    
    private var currentScenario: Scenario? {
        currentScenarios.first
    }

    var body: some View {
        ZStack {
            Constants.grey800
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Text("전화")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        isMyPagePresented = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("마이페이지")
                }
                
                PhoneCardView(
                    scenario: currentScenario
                )
                
                Button {
                    fakeCallCoordinator.startIncomingCall()
                    isFakeCallPresented = true
                } label: {
                    Text("Make a call")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            currentScenario == nil
                            ? Constants.main500.opacity(0.24)
                            : Constants.main500
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .disabled(currentScenario == nil)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
        }
        .fullScreenCover(
            isPresented: $isFakeCallPresented,
            onDismiss: stopFakeCallIfNeeded
        ) {
            fakeCallScreen
        }
        .sheet(isPresented: $isMyPagePresented) {
            MyPageView()
        }
    }

    @ViewBuilder
    private var fakeCallScreen: some View {
        if fakeCallCoordinator.phase == .incoming,
           let profile = fakeCallCoordinator.profile {
            IncomingFakeCallView(
                profile: profile,
                onAccept: fakeCallCoordinator.acceptCall,
                onDecline: finishFakeCall
            )
        } else if fakeCallCoordinator.phase.isActiveCall,
                  let profile = fakeCallCoordinator.profile,
                  let callStartedAt = fakeCallCoordinator.callStartedAt {
            ActiveFakeCallView(
                profile: profile,
                callStartedAt: callStartedAt,
                phase: fakeCallCoordinator.phase,
                currentInputLevel: fakeCallCoordinator.currentInputLevel,
                voiceMonitoringState: fakeCallCoordinator.voiceMonitoringState,
                isSpeakerEnabled: fakeCallCoordinator.isSpeakerEnabled,
                onEndCall: finishFakeCall,
                onSkipLine: fakeCallCoordinator.skipToNextLine,
                onSpeakerChange: fakeCallCoordinator.setSpeakerEnabled
            )
        } else if case let .failed(message) = fakeCallCoordinator.phase {
            failedCall(message: message)
        } else {
            preparingCall
        }
    }

    private var preparingCall: some View {
        ZStack {
            CallScreenBackground()
                .ignoresSafeArea()

            ProgressView()
                .tint(.white)
                .accessibilityLabel("가상 통화 준비 중")
        }
        .preferredColorScheme(.dark)
    }

    private func failedCall(message: String) -> some View {
        ZStack {
            CallScreenBackground()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Button("돌아가기", action: finishFakeCall)
                    .buttonStyle(.borderedProminent)
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
    }

    private func finishFakeCall() {
        fakeCallCoordinator.endCall()
        isFakeCallPresented = false
    }

    private func stopFakeCallIfNeeded() {
        guard fakeCallCoordinator.phase != .idle else { return }
        fakeCallCoordinator.endCall()
    }
}

#Preview {
    PhoneView()
}

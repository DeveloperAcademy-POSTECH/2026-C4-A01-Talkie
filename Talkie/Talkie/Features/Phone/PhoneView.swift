//
//  FakeCallView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI
import SwiftData

struct PhoneView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage(TalkiePreferenceKey.automaticCallRecordingEnabled)
    private var isAutomaticRecordingEnabled = false

    @State private var isFakeCallPresented = false
    @State private var fakeCallCoordinator = FakeCallCoordinator()
    @State private var historySaveError: String?

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
        NavigationStack {
            ZStack {
                Constants.grey800
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 28) {
                    phoneHeader

                    PhoneCardView(
                        scenario: currentScenario
                    )

                    Button(action: startFakeCall) {
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
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(
            isPresented: $isFakeCallPresented,
            onDismiss: stopFakeCallIfNeeded
        ) {
            fakeCallScreen
        }
        .alert(
            "통화내역 저장 실패",
            isPresented: Binding(
                get: { historySaveError != nil },
                set: { if !$0 { historySaveError = nil } }
            )
        ) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(historySaveError ?? "")
        }
    }

    private var phoneHeader: some View {
        HStack {
            Text("전화")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            NavigationLink {
                MyPageView()
            } label: {
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.08), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    }
            }
            .accessibilityLabel("마이페이지")
        }
    }

    @ViewBuilder
    private var fakeCallScreen: some View {
        if fakeCallCoordinator.phase == .incoming,
           let profile = fakeCallCoordinator.profile {
            IncomingFakeCallView(
                profile: profile,
                onAccept: acceptFakeCall,
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
        persist(fakeCallCoordinator.endCall())
        isFakeCallPresented = false
    }

    private func stopFakeCallIfNeeded() {
        guard fakeCallCoordinator.phase != .idle else { return }
        persist(fakeCallCoordinator.endCall(reason: .interrupted))
    }

    private func startFakeCall() {
        fakeCallCoordinator.startIncomingCall()
        isFakeCallPresented = true
    }

    private func acceptFakeCall() {
        fakeCallCoordinator.acceptCall(
            recordsAudio: isAutomaticRecordingEnabled,
            scenarioTitle: currentScenario?.title ?? "가상 통화"
        )
    }

    private func persist(_ completedSession: CompletedFakeCallSession?) {
        guard let completedSession else { return }

        let recording = completedSession.recording.map {
            CallRecording(
                fileName: $0.fileName,
                duration: $0.duration,
                fileSize: $0.fileSize,
                createdAt: $0.createdAt
            )
        }
        let session = CallSession(
            startedAt: completedSession.startedAt,
            endedAt: completedSession.endedAt,
            scenarioTitle: completedSession.scenarioTitle,
            callerName: completedSession.callerName,
            endReason: completedSession.endReason,
            recording: recording
        )
        recording?.session = session
        modelContext.insert(session)

        do {
            try modelContext.save()
        } catch {
            if let recording {
                try? CallRecordingFileStore().delete(fileName: recording.fileName)
            }
            modelContext.rollback()
            historySaveError = "통화내역을 저장하지 못했습니다."
        }
    }
}

#Preview {
    PhoneView()
}

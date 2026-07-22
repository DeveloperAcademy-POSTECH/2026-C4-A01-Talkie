//
//  PhoneView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftData
import SwiftUI

struct PhoneView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(TalkiePreferenceKey.automaticCallRecordingEnabled)
    private var isAutomaticRecordingEnabled = false

    @AppStorage(TalkiePreferenceKey.widgetCallRequestID)
    private var widgetCallRequestID = ""

    @State private var isFakeCallPresented = false
    @State private var isScenarioSelectionSheetPresented = false
    @State private var fakeCallCoordinator = FakeCallCoordinator()
    @State private var sosManager = SOSManager()
    @State private var widgetStatusManager = WidgetStatusManager()
    @State private var historySaveError: String?
    @State private var pendingSOSAction: ActiveCallSOSAction?
    @State private var queuedSOSAction: ActiveCallSOSAction?
    @State private var lastHandledWidgetCallRequestID = ""

    @Query(
        filter: #Predicate<Scenario> { scenario in
            scenario.isCurrentSelection == true
        },
        sort: \Scenario.createdAt,
        order: .reverse
    )
    private var currentScenarios: [Scenario]

    @Query(sort: \Scenario.createdAt, order: .reverse)
    private var scenarios: [Scenario]

    @Query(sort: \SafetyContact.name)
    private var safetyContacts: [SafetyContact]

    private var currentScenario: Scenario? {
        currentScenarios.first
    }

    private var currentScenarioWidgetSnapshot: String {
        guard let currentScenario else {
            return ""
        }

        return "\(currentScenario.title)|\(currentScenario.callerName)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Constants.grey800
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    phoneHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 32)

                    if !widgetStatusManager.isWidgetInstalled {
                        NavigationLink {
                            WidgetInstallUI()
                        } label: {
                            WidgetInstallBannerView()
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 24)
                    }

                    VStack(spacing: 20) {
                        PhoneCardView(
                            scenario: currentScenario,
                            onChangeScenario: {
                                isScenarioSelectionSheetPresented = true
                            }
                        )

                        callButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, widgetStatusManager.isWidgetInstalled ? 84 : 40)

                    Spacer()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(
                isPresented: $isFakeCallPresented,
                onDismiss: handleFakeCallDismissed
            ) {
                fakeCallScreen
            }
            .sheet(isPresented: $sosManager.shouldShowMessageCompose) {
                MessageComposerView(
                    mode: sosManager.messageComposeMode,
                    recipients: sosManager.messageRecipients,
                    body: sosManager.messageBody
                ) {
                    sosManager.shouldShowMessageCompose = false
                }
            }
            .sheet(isPresented: $isScenarioSelectionSheetPresented) {
                ScenarioSelectionSheetView(
                    scenarios: scenarios,
                    currentScenario: currentScenario,
                    onSelect: selectScenario
                )
                .presentationDetents([.height(520), .large])
                .presentationDragIndicator(.hidden)
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
            .alert(
                "SOS 실행 실패",
                isPresented: Binding(
                    get: { sosManager.currentError != nil },
                    set: { if !$0 { sosManager.currentError = nil } }
                )
            ) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(sosManager.currentError?.message ?? "")
            }
            .task {
                syncCurrentScenarioToWidget()
                handlePendingWidgetCallRequest()
                await widgetStatusManager.checkWidgetStatus()
            }
            .onChange(of: widgetCallRequestID) { _, _ in
                handlePendingWidgetCallRequest()
            }
            .onChange(of: currentScenarioWidgetSnapshot) { _, _ in
                syncCurrentScenarioToWidget()
                handlePendingWidgetCallRequest()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else {
                    return
                }

                Task {
                    syncCurrentScenarioToWidget()
                    await widgetStatusManager.checkWidgetStatus()
                }
            }
        }
    }
}

private extension PhoneView {
    var phoneHeader: some View {
        HStack {
            Text("대화 선택")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            NavigationLink {
                MyPageView()
            } label: {
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("마이페이지")
        }
    }

    var callButton: some View {
        Button(action: startFakeCall) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16, weight: .bold))

                Text("전화하기")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(Color.green)
            .padding(.horizontal, 10)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Constants.grey700)
            .cornerRadius(100)
            .opacity(currentScenario == nil ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(currentScenario == nil)
        .accessibilityLabel("가상 통화 시작")
    }

    var fakeCallScreen: some View {
        Group {
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
                    onSpeakerChange: fakeCallCoordinator.setSpeakerEnabled,
                    onShareLocation: { requestSOSAction(.locationShare) },
                    onEmergencySMS: { requestSOSAction(.emergencySMS) },
                    onEmergencyCall: { requestSOSAction(.emergencyCall) }
                )
            } else if case let .failed(message) = fakeCallCoordinator.phase {
                failedCall(message: message)
            } else {
                preparingCall
            }
        }
        .alert(item: $pendingSOSAction) { action in
            Alert(
                title: Text(action.confirmationTitle),
                message: Text(action.confirmationMessage),
                primaryButton: action.isEmergency
                    ? .destructive(Text(action.confirmButtonTitle)) {
                        finishFakeCallAndQueue(action)
                    }
                    : .default(Text(action.confirmButtonTitle)) {
                        finishFakeCallAndQueue(action)
                    },
                secondaryButton: .cancel()
            )
        }
    }

    var preparingCall: some View {
        ZStack {
            CallScreenBackground()
                .ignoresSafeArea()

            ProgressView()
                .tint(.white)
                .accessibilityLabel("가상 통화 준비 중")
        }
        .preferredColorScheme(.dark)
    }

    func failedCall(message: String) -> some View {
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

    func startFakeCall() {
        guard let currentScenario else {
            return
        }

        fakeCallCoordinator = FakeCallCoordinator(
            repository: MockFakeCallScriptRepository(
                displayName: currentScenario.callerName
            )
        )
        fakeCallCoordinator.startIncomingCall()
        isFakeCallPresented = true
    }

    func acceptFakeCall() {
        fakeCallCoordinator.acceptCall(
            recordsAudio: isAutomaticRecordingEnabled,
            scenarioTitle: currentScenario?.title ?? "가상 통화"
        )

        guard let profile = fakeCallCoordinator.profile,
              let startedAt = fakeCallCoordinator.callStartedAt else {
            return
        }

        Task {
            await FakeCallLiveActivityManager.shared.start(
                callerName: profile.displayName,
                startedAt: startedAt
            )
        }
    }

    func finishFakeCall() {
        persist(fakeCallCoordinator.endCall())
        endLiveActivity()
        isFakeCallPresented = false
    }

    func stopFakeCallIfNeeded() {
        guard fakeCallCoordinator.phase != .idle else { return }
        persist(fakeCallCoordinator.endCall(reason: .interrupted))
        endLiveActivity()
    }

    func handleFakeCallDismissed() {
        stopFakeCallIfNeeded()
        performQueuedSOSActionIfNeeded()
    }

    func requestSOSAction(_ action: ActiveCallSOSAction) {
        pendingSOSAction = action
    }

    func finishFakeCallAndQueue(_ action: ActiveCallSOSAction) {
        pendingSOSAction = nil
        persist(fakeCallCoordinator.endCall(reason: .sosTriggered))
        endLiveActivity()
        queuedSOSAction = action
        isFakeCallPresented = false
    }

    func endLiveActivity() {
        Task {
            await FakeCallLiveActivityManager.shared.end()
        }
    }

    func performQueuedSOSActionIfNeeded() {
        guard let action = queuedSOSAction else { return }
        queuedSOSAction = nil

        switch action {
        case .locationShare:
            sosManager.shareLocationToContacts(
                safetyContacts: safetyContacts
            )
        case .emergencySMS:
            sosManager.sendEmergencySMS112()
        case .emergencyCall:
            sosManager.callEmergencyServices()
        }
    }

    func persist(_ completedSession: CompletedFakeCallSession?) {
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

    func selectScenario(_ selectedScenario: Scenario) {
        for scenario in scenarios {
            scenario.isCurrentSelection = scenario === selectedScenario
        }

        do {
            try modelContext.save()
            WidgetScenarioStore.save(scenario: selectedScenario)
        } catch {
            modelContext.rollback()
            print("시나리오 선택 저장 실패: \(error.localizedDescription)")
        }
    }

    func syncCurrentScenarioToWidget() {
        guard let currentScenario else {
            return
        }

        WidgetScenarioStore.save(scenario: currentScenario)
    }

    func handlePendingWidgetCallRequest() {
        guard !widgetCallRequestID.isEmpty,
              widgetCallRequestID != lastHandledWidgetCallRequestID else {
            return
        }

        guard currentScenario != nil else {
            return
        }

        lastHandledWidgetCallRequestID = widgetCallRequestID
        widgetCallRequestID = ""
        startFakeCall()
    }
}

private enum ActiveCallSOSAction: String, Identifiable {
    case locationShare
    case emergencySMS
    case emergencyCall

    var id: String { rawValue }

    var confirmationTitle: String {
        switch self {
        case .locationShare:
            "안전 연락망에 위치를 공유할까요?"
        case .emergencySMS:
            "112 문자 신고를 준비할까요?"
        case .emergencyCall:
            "112에 전화할까요?"
        }
    }

    var confirmationMessage: String {
        switch self {
        case .locationShare:
            "현재 가상 통화를 종료하고 위치가 포함된 메시지 작성 화면을 엽니다. 메시지는 사용자가 직접 전송합니다."
        case .emergencySMS:
            "현재 가상 통화를 종료하고 위치가 포함된 \(SOSEmergencyDestination.displayName) 문자 작성 화면을 엽니다. 문자는 사용자가 직접 전송합니다."
        case .emergencyCall:
            "현재 가상 통화를 종료하고 시스템 전화 확인 화면을 엽니다. 확인하면 \(SOSEmergencyDestination.displayName)로 연결됩니다."
        }
    }

    var confirmButtonTitle: String {
        switch self {
        case .locationShare:
            "위치 공유 준비"
        case .emergencySMS:
            "문자 작성"
        case .emergencyCall:
            "112 전화"
        }
    }

    var isEmergency: Bool {
        self != .locationShare
    }
}

#Preview {
    PhoneView()
}

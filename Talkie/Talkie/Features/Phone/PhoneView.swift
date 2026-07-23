//
//  PhoneView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftData
import SwiftUI

/// 통화 탭의 데이터와 presentation을 연결하는 화면 조정자입니다.
/// 통화 상태 머신, SOS 실행, 저장 세부 구현은 각각 전담 객체에 위임합니다.
struct PhoneView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(TalkiePreferenceKey.automaticCallRecordingEnabled)
    private var isAutomaticRecordingEnabled = false

    @AppStorage(TalkiePreferenceKey.widgetCallRequestID)
    private var widgetCallRequestID = ""

    @Query(sort: \Scenario.createdAt, order: .reverse)
    private var scenarios: [Scenario]

    @Query(sort: \SafetyContact.name)
    private var safetyContacts: [SafetyContact]

    private let callSessionStore = CallSessionStore()

    @State private var isFakeCallPresented = false
    @State private var isScenarioSelectionSheetPresented = false
    @State private var fakeCallCoordinator = FakeCallCoordinator()
    @State private var sosManager = SOSManager()
    @State private var widgetStatusManager = WidgetStatusManager()
    @State private var historySaveError: String?
    @State private var pendingSOSAction: ActiveCallSOSAction?
    @State private var queuedSOSAction: ActiveCallSOSAction?
    @State private var lastHandledWidgetCallRequestID = ""
    @State private var selectedScenarioReference = ScenarioReference.defaultPreset

    private var availableScenarios: [ScenarioContent] {
        ScenarioLibrary.all(customScenarios: scenarios)
    }

    private var currentScenario: ScenarioContent {
        ScenarioLibrary.resolve(
            selectedScenarioReference,
            customScenarios: scenarios
        ) ?? PresetScenarioCatalog.kevin.content
    }

    private var currentScenarioWidgetSnapshot: String {
        "\(currentScenario.title)|\(currentScenario.callerName)"
    }

    private var availableScenarioReferences: [ScenarioReference] {
        availableScenarios.map(\.id)
    }

    private var isHistorySaveErrorPresented: Binding<Bool> {
        Binding(
            get: { historySaveError != nil },
            set: { if !$0 { historySaveError = nil } }
        )
    }

    private var isSOSErrorPresented: Binding<Bool> {
        Binding(
            get: { sosManager.currentError != nil },
            set: { if !$0 { sosManager.currentError = nil } }
        )
    }

    var body: some View {
        NavigationStack {
            PhoneHomeContentView(
                scenario: currentScenario,
                isWidgetInstalled: widgetStatusManager.isWidgetInstalled,
                onChangeScenario: presentScenarioSelection,
                onStartCall: startFakeCall
            )
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(
                isPresented: $isFakeCallPresented,
                onDismiss: handleFakeCallDismissed
            ) {
                FakeCallPresentationView(
                    coordinator: fakeCallCoordinator,
                    onAccept: acceptFakeCall,
                    onDecline: finishFakeCall,
                    onEndCall: finishFakeCall,
                    onShareLocation: { requestSOSAction(.locationShare) },
                    onEmergencySMS: { requestSOSAction(.emergencySMS) },
                    onEmergencyCall: { requestSOSAction(.emergencyCall) }
                )
                .alert(item: $pendingSOSAction) { action in
                    makeSOSConfirmationAlert(for: action)
                }
            }
            .sheet(isPresented: $sosManager.shouldShowMessageCompose) {
                MessageComposerView(
                    mode: sosManager.messageComposeMode,
                    recipients: sosManager.messageRecipients,
                    body: sosManager.messageBody,
                    onFinish: dismissMessageComposer
                )
            }
            .sheet(isPresented: $isScenarioSelectionSheetPresented) {
                ScenarioSelectionSheetView(
                    scenarios: availableScenarios,
                    currentScenario: currentScenario,
                    onSelect: selectScenario
                )
                .presentationDetents([.height(520), .large])
                .presentationDragIndicator(.hidden)
            }
            .alert("통화내역 저장 실패", isPresented: isHistorySaveErrorPresented) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(historySaveError ?? "")
            }
            .alert("SOS 실행 실패", isPresented: isSOSErrorPresented) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(sosManager.currentError?.message ?? "")
            }
            .task {
                await preparePhoneScreen()
            }
            .onChange(of: widgetCallRequestID, handleWidgetCallRequestChange)
            .onChange(of: currentScenarioWidgetSnapshot, handleCurrentScenarioChange)
            .onChange(of: availableScenarioReferences, handleScenarioListChange)
            .onChange(of: scenePhase, handleScenePhaseChange)
        }
    }
}

// MARK: - Presentation

private extension PhoneView {
    func presentScenarioSelection() {
        isScenarioSelectionSheetPresented = true
    }

    func dismissMessageComposer() {
        sosManager.shouldShowMessageCompose = false
    }

    func makeSOSConfirmationAlert(for action: ActiveCallSOSAction) -> Alert {
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

// MARK: - Call lifecycle

private extension PhoneView {
    func startFakeCall() {
        fakeCallCoordinator.startIncomingCall(
            repository: ScenarioFakeCallScriptRepository(content: currentScenario)
        )
        isFakeCallPresented = true
    }

    func acceptFakeCall() {
        fakeCallCoordinator.acceptCall(
            recordsAudio: isAutomaticRecordingEnabled,
            scenarioTitle: currentScenario.title
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

    func endLiveActivity() {
        Task {
            await FakeCallLiveActivityManager.shared.end()
        }
    }

    func persist(_ completedSession: CompletedFakeCallSession?) {
        guard let completedSession else { return }

        do {
            try callSessionStore.save(completedSession, in: modelContext)
        } catch {
            historySaveError = "통화내역을 저장하지 못했습니다."
        }
    }
}

// MARK: - SOS flow

private extension PhoneView {
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

    func performQueuedSOSActionIfNeeded() {
        guard let action = queuedSOSAction else { return }
        queuedSOSAction = nil

        switch action {
        case .locationShare:
            sosManager.shareLocationToContacts(safetyContacts: safetyContacts)
        case .emergencySMS:
            sosManager.sendEmergencySMS112()
        case .emergencyCall:
            sosManager.callEmergencyServices()
        }
    }
}

// MARK: - Scenario and widget synchronization

private extension PhoneView {
    func preparePhoneScreen() async {
        restoreScenarioSelection()
        syncCurrentScenarioToWidget()
        handlePendingWidgetCallRequest()
        await widgetStatusManager.checkWidgetStatus()
    }

    func selectScenario(_ selectedScenario: ScenarioContent) {
        selectedScenarioReference = selectedScenario.id
        ScenarioSelectionStore.save(selectedScenario.id)
        WidgetScenarioStore.save(scenario: selectedScenario)
    }

    func syncCurrentScenarioToWidget() {
        WidgetScenarioStore.save(scenario: currentScenario)
    }

    func restoreScenarioSelection() {
        selectedScenarioReference = ScenarioSelectionStore.load()
        normalizeScenarioSelection()
    }

    func normalizeScenarioSelection() {
        guard ScenarioLibrary.resolve(
            selectedScenarioReference,
            customScenarios: scenarios
        ) == nil else { return }

        selectedScenarioReference = .defaultPreset
        ScenarioSelectionStore.resetToDefault()
    }

    func handlePendingWidgetCallRequest() {
        guard !widgetCallRequestID.isEmpty,
              widgetCallRequestID != lastHandledWidgetCallRequestID else {
            return
        }

        lastHandledWidgetCallRequestID = widgetCallRequestID
        widgetCallRequestID = ""
        startFakeCall()
    }

    func handleWidgetCallRequestChange(_: String, _: String) {
        handlePendingWidgetCallRequest()
    }

    func handleCurrentScenarioChange(_: String, _: String) {
        syncCurrentScenarioToWidget()
        handlePendingWidgetCallRequest()
    }

    func handleScenarioListChange(_: [ScenarioReference], _: [ScenarioReference]) {
        normalizeScenarioSelection()
    }

    func handleScenePhaseChange(_ oldPhase: ScenePhase, _ newPhase: ScenePhase) {
        guard newPhase == .active else { return }

        Task {
            // 백그라운드에 있는 동안에는 진행 중 통화를 유지합니다. 다시 active가 됐을 때
            // 실제 통화 상태가 없다면 크래시나 비정상 presentation 종료로 남은 Activity를 정리합니다.
            if !fakeCallCoordinator.phase.isActiveCall {
                await FakeCallLiveActivityManager.shared.end()
            }
            syncCurrentScenarioToWidget()
            await widgetStatusManager.checkWidgetStatus()
        }
    }
}

#Preview {
    PhoneView()
}

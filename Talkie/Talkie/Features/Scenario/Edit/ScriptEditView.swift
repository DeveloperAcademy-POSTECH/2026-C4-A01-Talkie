//
//  ScriptEditView.swift
//  Talkie
//
//  Created by DS on 7/18/26.
//

import SwiftUI
import SwiftData

struct ScriptEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ScriptEditViewModel
    @State private var isEditingScripts = false
    @FocusState private var focusedScriptLineID: PersistentIdentifier?

    private let actionButtonTitle: String
    private let onComplete: (() -> Void)?

    init(
        scenario: Scenario,
        modelContext: ModelContext,
        actionButtonTitle: String = "시나리오 생성하기",
        insertsScenarioOnComplete: Bool = false,
        onComplete: (() -> Void)? = nil
    ) {
        _viewModel = State(
            initialValue: ScriptEditViewModel(
                scenario: scenario,
                modelContext: modelContext,
                insertsScenarioOnComplete: insertsScenarioOnComplete
            )
        )
        self.actionButtonTitle = actionButtonTitle
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }

            VStack(alignment: .leading, spacing: 0) {
                navigationBar
                recordingProgressHeader
                scriptLineList
            }
            .padding(.bottom, 88)

            bottomActionButton
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
        .alert(
            "저장 실패",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearErrorMessage() } }
            )
        ) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var navigationBar: some View {
        DepthNavigationBar(title: viewModel.scenario.title) {
            dismiss()
        } trailingContent: {
            trailingNavigationControl
        }
    }

    @ViewBuilder
    private var trailingNavigationControl: some View {
        if viewModel.canEditScripts {
            Button {
                withAnimation {
                    isEditingScripts.toggle()
                }
            } label: {
                if isEditingScripts {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Constants.grey800)
                        .frame(width: 48, height: 48)
                        .background(Constants.main500)
                        .clipShape(Circle())
                } else {
                    Text("편집")
                        .font(Font.pretendard(.medium, size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(40)
                }
            }
            .buttonStyle(.plain)
        } else {
            Text("읽기 전용")
                .font(Font.pretendard(.medium, size: 14))
                .foregroundColor(.white.opacity(0.72))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .cornerRadius(40)
        }
    }

    private var recordingProgressHeader: some View {
        (
            Text("대화 문장 녹음 진행도 ")
                .font(Font.pretendard(.semiBold, size: 16))
                .foregroundColor(.white)
            + Text("\(viewModel.recordedCount)")
                .font(Font.pretendard(.regular, size: 16))
                .foregroundColor(Constants.primaryNormal)
            + Text("/\(viewModel.totalCount)")
                .font(Font.pretendard(.regular, size: 16))
                .foregroundColor(Constants.grey300)
        )
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .padding(.bottom, 16)
    }

    private var scriptLineList: some View {
        List {
            ForEach(viewModel.sortedScriptLines) { scriptLine in
                ScriptLineCardView(
                    scriptLine: scriptLine,
                    isRecording: viewModel.isRecording(scriptLine),
                    isPlaying: viewModel.isPlaying(scriptLine),
                    isEditing: isEditingScripts,
                    isReadOnly: viewModel.isPresetScenario,
                    focusedScriptLineID: $focusedScriptLineID,
                    onPlay: {
                        viewModel.playRecording(for: scriptLine)
                    },
                    onRecordToggle: {
                        viewModel.toggleRecording(for: scriptLine)
                    },
                    onTextChange: { text in
                        viewModel.updateText(text, for: scriptLine)
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(
                    EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
                )
                .deleteDisabled(!isEditingScripts || !viewModel.canEditScripts)
                .moveDisabled(!isEditingScripts || !viewModel.canEditScripts)
            }
            .onMove { source, destination in
                guard isEditingScripts else { return }
                viewModel.moveScriptLines(from: source, to: destination)
            }
            .onDelete { offsets in
                guard isEditingScripts else { return }
                dismissKeyboard()
                viewModel.deleteScriptLines(at: offsets)
            }

            if viewModel.canEditScripts && !isEditingScripts {
                addScriptLineButton
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(
                        EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
                    )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .environment(
            \.editMode,
            .constant(isEditingScripts ? EditMode.active : EditMode.inactive)
        )
    }

    private var addScriptLineButton: some View {
        Button {
            viewModel.addScriptLine()
        } label: {
            Image(systemName: "plus.circle")
                .font(.system(size: 30, weight: .light))
                .foregroundColor(Constants.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .padding(16)
                .background(Constants.grey700)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("대사 추가")
    }

    private var bottomActionButton: some View {
        Button {
            if viewModel.completeEditing() {
                if let onComplete {
                    onComplete()
                } else {
                    dismiss()
                }
            }
        } label: {
            Text(viewModel.isPresetScenario ? "돌아가기" : actionButtonTitle)
                .font(Font.pretendard(.semiBold, size: 17))
                .foregroundColor(Constants.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 16)
                .background(Constants.primaryNormal)
                .cornerRadius(16)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 36)
        .background(Color.black)
    }

    private func dismissKeyboard() {
        focusedScriptLineID = nil
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Scenario.self,
        ScriptLine.self,
        AudioClipMetadata.self,
        configurations: config
    )

    let sampleScenario = Scenario(title: "집에 오는 길 통화", callerName: "엄마")

    let line1 = ScriptLine(text: "여보세요?", sortOrder: 0, isRecorded: true, scenario: sampleScenario)
    let line2 = ScriptLine(text: "아직 밖이야? 집에 오는 길 맞지?", sortOrder: 1, isRecorded: true, scenario: sampleScenario)
    let line3 = ScriptLine(text: "내가 맨날 잔소리한다고 하는데 뉴스 보면 별일이 다 있어서 그래.", sortOrder: 2, isRecorded: true, scenario: sampleScenario)

    sampleScenario.scriptLines = [line1, line2, line3]
    container.mainContext.insert(sampleScenario)

    return ScriptEditView(scenario: sampleScenario, modelContext: container.mainContext)
        .modelContainer(container)
}

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
    @State private var pendingDeleteOffsets: IndexSet?
    @State private var isShowingDeleteConfirmation = false

    private let actionButtonTitle: String
    private let onComplete: (() -> Void)?

    init(
        scenario: Scenario,
        modelContext: ModelContext,
        actionButtonTitle: String = "대화 생성",
        onComplete: (() -> Void)? = nil
    ) {
        _viewModel = State(
            initialValue: ScriptEditViewModel(scenario: scenario, modelContext: modelContext)
        )
        self.actionButtonTitle = actionButtonTitle
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            Constants.grey800
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                navigationBar
                recordingProgressHeader
                scriptLineList
                bottomActionButton
            }
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
        .alert(
            "정말로 삭제하시겠습니까?",
            isPresented: $isShowingDeleteConfirmation
        ) {
            Button("취소", role: .cancel) {
                pendingDeleteOffsets = nil
            }

            Button("삭제", role: .destructive) {
                confirmPendingDeletion()
            }
        } message: {
            Text("삭제한 대사는 되돌릴 수 없습니다.")
        }
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
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }

            Spacer()

            Text(viewModel.scenario.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            trailingNavigationControl
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
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
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Constants.grey800)
                        .frame(width: 56, height: 56)
                        .background(Constants.main500)
                        .clipShape(Circle())
                } else {
                    Text("편집")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(40)
                }
            }
        } else {
            Text("읽기 전용")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.72))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .cornerRadius(40)
        }
    }

    private var recordingProgressHeader: some View {
        HStack(spacing: 6) {
            Text("대화 문장 녹음 진행도")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 0) {
                Text("\(viewModel.recordedCount)")
                    .foregroundColor(Constants.main500)

                Text("/\(viewModel.totalCount)")
                    .foregroundColor(Constants.grey300)
            }
            .font(.system(size: 16, weight: .bold))
        }
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
                    isEditing: isEditingScripts,
                    isReadOnly: viewModel.isPresetScenario,
                    onPlay: {
                        viewModel.playRecording(for: scriptLine)
                    },
                    onRecordToggle: {
                        viewModel.toggleRecording(for: scriptLine)
                    },
                    onTextChange: { text in
                        viewModel.updateText(text, for: scriptLine)
                    },
                    onDelete: {
                        requestDelete(scriptLine)
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(
                    EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                )
                .deleteDisabled(!isEditingScripts || !viewModel.canEditScripts)
                .moveDisabled(!isEditingScripts || !viewModel.canEditScripts)
            }
            .onMove { source, destination in
                guard isEditingScripts else { return }
                viewModel.moveScriptLines(from: source, to: destination)
            }

            if viewModel.canEditScripts {
                addScriptLineButton
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(
                        EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                    )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(
            \.editMode,
            .constant(isEditingScripts ? EditMode.active : EditMode.inactive)
        )
    }

    private var addScriptLineButton: some View {
        Button {
            viewModel.addScriptLine()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white.opacity(0.48))
                .frame(maxWidth: .infinity)
                .frame(height: 84)
                .background(Constants.grey700)
                .cornerRadius(16)
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
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Constants.main500)
                .cornerRadius(16)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func requestDelete(_ scriptLine: ScriptLine) {
        guard let index = viewModel.sortedScriptLines.firstIndex(where: { $0 === scriptLine }) else {
            return
        }

        requestDelete(IndexSet(integer: index))
    }

    private func requestDelete(_ offsets: IndexSet) {
        pendingDeleteOffsets = offsets
        isShowingDeleteConfirmation = true
    }

    private func confirmPendingDeletion() {
        guard let pendingDeleteOffsets else {
            return
        }

        viewModel.deleteScriptLines(at: pendingDeleteOffsets)
        self.pendingDeleteOffsets = nil
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

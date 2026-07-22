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

            if isShowingDeleteConfirmation {
                deleteConfirmationOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
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
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)

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
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Constants.grey800)
                        .frame(width: 44, height: 44)
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
                    .foregroundColor(Constants.primaryNormal)

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
            .onDelete { offsets in
                guard isEditingScripts else { return }
                requestDelete(offsets)
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
                .font(.system(size: 30, weight: .light))
                .foregroundColor(Constants.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 152)
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
                .background(Constants.primaryNormal)
                .cornerRadius(16)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var deleteConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .onTapGesture {
                    cancelPendingDeletion()
                }

            VStack(alignment: .center, spacing: 20) {
                VStack(alignment: .center, spacing: 6) {
                    Text("대화 문장을 삭제하시겠습니까?")
                        .font(Font.custom("Pretendard", size: 18).weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Constants.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .top)

                    Text("다시 복구할 수 없습니다.")
                        .font(Font.custom("Pretendard", size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Constants.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .top)
                }

                Image("Group 18")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 83)

                HStack(alignment: .center, spacing: 10) {
                    Button(action: cancelPendingDeletion) {
                        Text("취소")
                            .font(Font.custom("Pretendard", size: 16).weight(.semibold))
                            .foregroundColor(Constants.textInverse)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 44)
                            .padding(.vertical, 10)
                            .background(Constants.surfaceDisable)
                            .cornerRadius(12)
                    }

                    Button(action: confirmPendingDeletion) {
                        Text("삭제하기")
                            .font(Font.custom("Pretendard", size: 16).weight(.semibold))
                            .foregroundColor(Constants.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 44)
                            .padding(.vertical, 10)
                            .background(Constants.primaryNormal)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)
            .padding(.bottom, 16)
            .frame(width: 336, alignment: .top)
            .background(Constants.bgRegular)
            .cornerRadius(24)
        }
    }

    private func requestDelete(_ offsets: IndexSet) {
        pendingDeleteOffsets = offsets
        isShowingDeleteConfirmation = true
    }

    private func cancelPendingDeletion() {
        pendingDeleteOffsets = nil
        isShowingDeleteConfirmation = false
    }

    private func confirmPendingDeletion() {
        guard let pendingDeleteOffsets else {
            return
        }

        viewModel.deleteScriptLines(at: pendingDeleteOffsets)
        self.pendingDeleteOffsets = nil
        isShowingDeleteConfirmation = false
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

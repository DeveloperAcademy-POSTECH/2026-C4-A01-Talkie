//
//  ScenarioDetailView.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import SwiftUI
import SwiftData

struct ScenarioDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ScenarioDetailViewModel
    @State private var isShowingInfoEditView = false
    @State private var isShowingScriptEditView = false
    @State private var isShowingDeleteConfirmation = false

    init(scenario: Scenario) {
        _viewModel = State(initialValue: ScenarioDetailViewModel(scenario: scenario))
    }

    init(preset: PresetScenario) {
        _viewModel = State(initialValue: ScenarioDetailViewModel(preset: preset))
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                navigationBar
                scenarioHeader
                scriptLineList
            }
            .disabled(isShowingDeleteConfirmation)

            if isShowingDeleteConfirmation {
                DeleteConfirmationOverlay(
                    title: "시나리오를 삭제하시겠습니까?",
                    onCancel: cancelDeleteScenario,
                    onConfirm: deleteScenario
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
        .navigationDestination(isPresented: $isShowingInfoEditView) {
            if let scenario = viewModel.customScenario {
                ScenarioInfoEditView(scenario: scenario)
            }
        }
        .navigationDestination(isPresented: $isShowingScriptEditView) {
            if let scenario = viewModel.customScenario {
                ScriptEditView(
                    scenario: scenario,
                    modelContext: modelContext,
                    actionButtonTitle: "수정하기"
                ) {
                    isShowingScriptEditView = false
                }
            }
        }
        .alert(
            "작업 실패",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearErrorMessage() } }
            )
        ) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.refreshContent()
        }
        .onDisappear {
            viewModel.stopPlayback()
        }
    }

    private var navigationBar: some View {
        DepthNavigationBar {
            dismiss()
        } trailingContent: {
            if viewModel.canManageScenario {
                Menu {
                    Button("제목/발화자 수정") {
                        isShowingInfoEditView = true
                    }

                    Button("시나리오 수정") {
                        isShowingScriptEditView = true
                    }

                    Button("시나리오 삭제", role: .destructive) {
                        isShowingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.grey100)
                        .frame(width:36, height:36)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("시나리오 옵션 더보기")
            }
        }
    }

    private var scenarioHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.content.title)
                        .font(Font.pretendard(.bold, size: 20))
                        .foregroundColor(.grey100)

                    Text("발화자 | \(viewModel.content.callerName)")
                        .font(Font.pretendard(.medium, size: 14))
                        .foregroundColor(.grey500)
                }

                Spacer()

                Button {
                    viewModel.togglePlayAll()
                } label: {
                    Label(
                        viewModel.isPlayingAll ? "정지" : "전체 듣기",
                        systemImage: viewModel.isPlayingAll ? "pause.fill" : "play.fill"
                    )
                    .font(Font.pretendard(.semiBold, size: 16))
                    .foregroundColor(.main500)
                    .padding(.leading, 12)
                    .padding(.trailing, 16)
                    .padding(.vertical, 10)
                    .background(Constants.main200A5)
                    .cornerRadius(69.23077)
                    .overlay {
                        RoundedRectangle(cornerRadius: 69.23077)
                            .inset(by: 0.5)
                            .stroke(.main500, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 36)
        .padding(.bottom, 24)
    }

    private var scriptLineList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.sortedScriptLines) { scriptLine in
                    scriptLineRow(scriptLine)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func scriptLineRow(_ scriptLine: ScenarioLineContent) -> some View {
        let isRecorded = scriptLine.audioSource != nil

        return VStack(alignment: .leading, spacing: 24) {
            RecordingStateBadgeView(
                isRecording: false,
                isRecorded: isRecorded
            )

            HStack(alignment: .center, spacing: 14) {
                Text(scriptLine.text)
                    .font(Font.pretendard(.regular, size: 16))
                    .foregroundColor(.grey100)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isRecorded {
                    Button {
                        viewModel.playSingleLine(scriptLine)
                    } label: {
                        Image(systemName: viewModel.isPlaying(scriptLine) ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(viewModel.isPlaying(scriptLine) ? .main500 : .grey100)
                            .frame(width: 36, height: 36)
                            .background(.grey900)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("\(scriptLine.text) 재생")
                    .accessibilityValue(viewModel.isPlaying(scriptLine) ? "재생 중" : "정지됨")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(viewModel.isPlaying(scriptLine) ? .main500.opacity(0.22) : .grey700)
                .overlay {
                    if viewModel.isPlaying(scriptLine) {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.main500.opacity(0.9), lineWidth: 1)
                    }
                }
        )
    }

    private func deleteScenario() {
        if viewModel.deleteScenario(using: modelContext) {
            isShowingDeleteConfirmation = false
            dismiss()
        } else {
            isShowingDeleteConfirmation = false
        }
    }

    private func cancelDeleteScenario() {
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

    let scenario = Scenario(title: "사용자가 입력한 제목", callerName: "엄마")
    scenario.scriptLines = [
        ScriptLine(text: "여보세요?", sortOrder: 0, scenario: scenario),
        ScriptLine(text: "아직 밖이야? 집에 오는 길 맞지?", sortOrder: 1, scenario: scenario),
        ScriptLine(text: "집 거의 다 오면 엄마한테 한 번만 더 전화하거나 문자 보내.", sortOrder: 2, scenario: scenario)
    ]
    container.mainContext.insert(scenario)

    return NavigationStack {
        ScenarioDetailView(scenario: scenario)
            .modelContainer(container)
    }
}

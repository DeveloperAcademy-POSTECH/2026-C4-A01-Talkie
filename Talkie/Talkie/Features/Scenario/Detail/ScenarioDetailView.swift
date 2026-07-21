//
//  ScenarioDetailView.swift
//  Talkie
//
//  Created by Codex on 7/21/26.
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

    var body: some View {
        ZStack {
            Constants.grey800
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                navigationBar
                scenarioHeader
                scriptLineList
            }
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
        .navigationDestination(isPresented: $isShowingInfoEditView) {
            ScenarioInfoEditView(scenario: viewModel.scenario)
        }
        .navigationDestination(isPresented: $isShowingScriptEditView) {
            ScriptEditView(
                scenario: viewModel.scenario,
                modelContext: modelContext,
                actionButtonTitle: "수정하기"
            ) {
                isShowingScriptEditView = false
            }
        }
        .alert(
            "시나리오를 삭제하시겠습니까?",
            isPresented: $isShowingDeleteConfirmation
        ) {
            Button("취소", role: .cancel) { }

            Button("삭제하기", role: .destructive) {
                deleteScenario()
            }
        } message: {
            Text("다시 복구할 수 없습니다.")
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
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.grey100)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var scenarioHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.scenario.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.grey100)

                    Text("발화자 | \(viewModel.callerName)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.grey300)
                }

                Spacer()

                Button {
                    viewModel.togglePlayAll()
                } label: {
                    Label(
                        viewModel.isPlayingAll ? "정지" : "전체 듣기",
                        systemImage: viewModel.isPlayingAll ? "pause.fill" : "play.fill"
                    )
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.main500)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay {
                        Capsule()
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

    private func scriptLineRow(_ scriptLine: ScriptLine) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(scriptLine.text)
                .font(.custom("Pretendard", size: 16))
                .foregroundColor(.grey100)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

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
            .disabled(!scriptLine.isRecorded)
            .opacity(scriptLine.isRecorded ? 1 : 0.36)
            .accessibilityLabel("대사 재생")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.isPlaying(scriptLine) ? .main500.opacity(0.22) : .grey700)
                .overlay {
                    if viewModel.isPlaying(scriptLine) {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.main500.opacity(0.9), lineWidth: 1)
                    }
                }
        )
    }

    private func deleteScenario() {
        if viewModel.deleteScenario(using: modelContext) {
            dismiss()
        }
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

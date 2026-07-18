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

    init(scenario: Scenario, modelContext: ModelContext) {
        _viewModel = State(
            initialValue: ScriptEditViewModel(scenario: scenario, modelContext: modelContext)
        )
    }

    var body: some View {
        ZStack {
            Constants.grey800
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // 1. 상단 네비게이션 바
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
                    Button { } label: {
                        Text("편집")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                // 2. 녹음 진행도 레이블 영역
                HStack(spacing: 6) {
                    Text("대화 문장 녹음 진행도")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    HStack(spacing: 0) {
                        Text("\(viewModel.recordedCount)").foregroundColor(Constants.main500)
                        Text("/\(viewModel.totalCount)").foregroundColor(Constants.grey300)
                    }
                    .font(.system(size: 16, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
                .padding(.bottom, 24)
                
                // 3. 대사 리스트 스크롤 뷰
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.sortedScriptLines) { scriptLine in
                            ScriptLineCardView(
                                scriptLine: scriptLine,
                                isRecording: viewModel.isRecording(scriptLine),
                                onPlay: {
                                    viewModel.playRecording(for: scriptLine)
                                },
                                onRecordToggle: {
                                    viewModel.toggleRecording(for: scriptLine)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // 4. 하단 고정 버튼
                Button { } label: {
                    Text("대화 생성")
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
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview Fix
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Scenario.self, CallerProfile.self, ScriptLine.self, configurations: config
    )
    
    let sampleProfile = CallerProfile(name: "엄마")
    let sampleScenario = Scenario(title: "집에 오는 길 통화", callerProfile: sampleProfile)
    
    let line1 = ScriptLine(text: "여보세요?", sortOrder: 0, isRecorded: true, scenario: sampleScenario)
    let line2 = ScriptLine(text: "아직 밖이야? 집에 오는 길 맞지?", sortOrder: 1, isRecorded: true, scenario: sampleScenario)
    let line3 = ScriptLine(text: "내가 맨날 잔소리한다고 하는데 뉴스 보면 별일이 다 있어서 그래.", sortOrder: 2, isRecorded: true, scenario: sampleScenario)
    let line4 = ScriptLine(text: "오늘 뭐 입고 나갔더라? 아침에 정신없이 나가서 기억이 안 나네.", sortOrder: 3, scenario: sampleScenario)
    let line5 = ScriptLine(text: "집 거의 다 오면 엄마한테 한 번만 더 전화하거나 문자 보내. 기다리고 있을게.", sortOrder: 4, scenario: sampleScenario)
    
    sampleScenario.scriptLines = [line1, line2, line3, line4, line5]
    container.mainContext.insert(sampleScenario)
    
    return ScriptEditView(scenario: sampleScenario, modelContext: container.mainContext)
        .modelContainer(container)
}

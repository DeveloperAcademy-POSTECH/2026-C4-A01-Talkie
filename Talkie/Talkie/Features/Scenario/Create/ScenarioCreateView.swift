//
//  ScenarioCreateView.swift
//  Talkie
//
//  Created by DS on 7/18/26.
//

import SwiftUI
import SwiftData

struct ScenarioCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel = ScenarioCreateViewModel()
    private let onComplete: (() -> Void)?

    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        ZStack {
            // 1. 피그마 전체 배경 톤 반영
            Constants.grey800
                .ignoresSafeArea()
            VStack(alignment: .leading) {
                
                // 2. 커스텀 상단 뒤로가기 바 영역
                DepthNavigationBar {
                    dismiss()
                }

                
                // 3. 메인 타이틀
                Text("시나리오 제목과 발화자를 입력해주세요.")
                    .font(Font.custom("Pretendard", size: 20).weight(.semibold))
                    .foregroundColor(Constants.grey100)
                    .frame(maxWidth: .infinity, minHeight: 27, maxHeight: 27, alignment: .topLeading)
                    .padding(.horizontal, 16)
                    .padding(.top, 32)
                
                VStack(alignment: .leading, spacing: 32) {
                    // 4. 시나리오 제목 입력 섹션
                    scenarioTextField(
                        title: "시나리오 제목",
                        placeholder: "엄마와의 대화",
                        text: $viewModel.scenarioTitle
                    )

                    // 5. 발화자 입력 섹션
                    scenarioTextField(
                        title: "발화자",
                        placeholder: "엄마",
                        text: $viewModel.callerName
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(Constants.bgRegular)
                
                Spacer()
                
                // 6. 하단 '다음으로' 버튼
                Button {
                    viewModel.saveInitialScenario(modelContext: modelContext)
                } label: {
                    HStack(alignment: .center, spacing: 10) {
                        Text("다음으로")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Constants.grey100)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(viewModel.isFormValid ? Constants.main500 : Constants.grey500)
                    .cornerRadius(16)
                }
                .disabled(!viewModel.isFormValid)
                .padding(.horizontal, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(
            "저장 실패",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .navigationDestination(isPresented: $viewModel.shouldNavigateToScriptEdit) {
            if let scenario = viewModel.createdScenario {
                ScriptEditView(
                    scenario: scenario,
                    modelContext: modelContext
                ) {
                    viewModel.shouldNavigateToScriptEdit = false

                    if let onComplete {
                        onComplete()
                    } else {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension ScenarioCreateView {
    func scenarioTextField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(Font.custom("Pretendard", size: 14).weight(.medium))
                .foregroundColor(Constants.textSecondary)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            TextField(
                "",
                text: text,
                prompt: Text(placeholder)
                    .foregroundColor(Constants.grey500)
            )
            .font(Font.custom("Pretendard", size: 16))
            .foregroundColor(Constants.grey100)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Constants.surfaceTextField)
            .cornerRadius(16)
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Scenario.self,
        ScriptLine.self,
        configurations: config
    )
    
    return NavigationStack {
        ScenarioCreateView()
            .modelContainer(container)
    }
}

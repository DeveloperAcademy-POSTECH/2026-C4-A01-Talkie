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
            VStack(alignment: .leading, spacing: 28) {
                
                // 2. 커스텀 상단 뒤로가기 바 영역
                HStack(alignment: .center, spacing: 10) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.grey100)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 3. 메인 타이틀
                Text("시나리오 제목과 발화자를 입력해주세요.")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.grey100)
                
                // 4. 시나리오 제목 입력 섹션
                VStack(alignment: .leading, spacing: 9) {
                    Text("시나리오 제목")
                        .font(.custom("Pretendard", size: 14).weight(.medium))
                        .foregroundColor(.grey300)
                    
                    TextField("", text: $viewModel.scenarioTitle, prompt:
                        Text("예: 엄마와의 통화")
                            .foregroundColor(.grey500)
                    )
                    .font(.custom("Pretendard", size: 16))
                    .foregroundColor(.grey100)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(.grey700)
                    .cornerRadius(16)
                }
                
                // 5. 발화자 입력 섹션
                VStack(alignment: .leading, spacing: 9) {
                    Text("발화자")
                        .font(.custom("Pretendard", size: 14).weight(.medium))
                        .foregroundColor(.grey300)
                    
                    TextField("", text: $viewModel.callerName, prompt:
                        Text("엄마")
                            .foregroundColor(.grey500)
                    )
                    .font(.custom("Pretendard", size: 16))
                    .foregroundColor(.grey100)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(.grey700)
                    .cornerRadius(16)
                }
                
                Spacer()
                
                // 6. 하단 '다음으로' 버튼
                Button {
                    viewModel.saveInitialScenario(modelContext: modelContext)
                } label: {
                    HStack(alignment: .center, spacing: 10) {
                        Text("다음으로")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.grey100)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(viewModel.isFormValid ? .main500 : .grey500)
                    .cornerRadius(16)
                }
                .disabled(!viewModel.isFormValid)
            }
            .padding(.horizontal, 16) 
            .padding(.vertical, 32)
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

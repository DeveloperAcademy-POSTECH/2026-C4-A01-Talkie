//
//  ScenarioInfoEditView.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import SwiftUI
import SwiftData

struct ScenarioInfoEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let scenario: Scenario

    @State private var title: String
    @State private var callerName: String
    @State private var errorMessage: String?
    @FocusState private var focusedField: ScenarioInfoEditField?

    init(scenario: Scenario) {
        self.scenario = scenario
        _title = State(initialValue: scenario.title)
        _callerName = State(initialValue: scenario.callerName)
    }

    private var isFormValid: Bool {
        !trimmedTitle.isEmpty && !trimmedCallerName.isEmpty
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                }

            VStack(alignment: .leading, spacing: 0) {
                navigationBar

                VStack(alignment: .leading, spacing: 32) {
                    inputSection(
                        title: "시나리오 제목",
                        placeholder: "엄마와의 대화",
                        text: $title,
                        focusField: .scenarioTitle
                    )

                    inputSection(
                        title: "발화자",
                        placeholder: "엄마",
                        text: $callerName,
                        focusField: .callerName
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity, alignment: .topLeading)

                Spacer()

                Button {
                    saveScenarioInfo()
                } label: {
                    HStack(alignment: .center, spacing: 10) {
                        Text("수정하기")
                            .font(Font.pretendard(.semiBold, size: 17))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Constants.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(isFormValid ? Constants.main500 : Constants.surfaceDisable)
                    .cornerRadius(16)
                }
                .disabled(!isFormValid)
                .padding(.horizontal, 16)
                .padding(.bottom, 36)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
        .alert(
            "저장 실패",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var navigationBar: some View {
        DepthNavigationBar {
            dismiss()
        }
    }

    private func inputSection(
        title: String,
        placeholder: String,
        text: Binding<String>,
        focusField: ScenarioInfoEditField
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(Font.pretendard(.medium, size: 14))
                .foregroundColor(Constants.textSecondary)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            TextField(
                "",
                text: text,
                prompt: Text(placeholder)
                    .foregroundColor(Constants.grey500)
            )
                .font(Font.pretendard(.regular, size: 16))
                .foregroundColor(Constants.grey100)
                .focused($focusedField, equals: focusField)
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .background(Constants.surfaceTextField)
                .cornerRadius(16)
        }
    }

    private func saveScenarioInfo() {
        guard isFormValid else {
            errorMessage = "시나리오 제목과 발화자를 모두 입력해주세요."
            return
        }

        scenario.title = trimmedTitle
        scenario.callerName = trimmedCallerName
        scenario.updatedAt = Date()

        do {
            try modelContext.save()
            CloudSyncChangeTracker.savedScenario(scenario, includeScriptLines: false)
            dismiss()
        } catch {
            errorMessage = "시나리오 정보를 저장하지 못했습니다."
            print("시나리오 정보 저장 실패: \(error.localizedDescription)")
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCallerName: String {
        callerName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum ScenarioInfoEditField: Hashable {
    case scenarioTitle
    case callerName
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Scenario.self,
        ScriptLine.self,
        AudioClipMetadata.self,
        configurations: config
    )

    let scenario = Scenario(title: "엄마와의 대화", callerName: "엄마")
    container.mainContext.insert(scenario)

    return NavigationStack {
        ScenarioInfoEditView(scenario: scenario)
            .modelContainer(container)
    }
}

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
            Constants.grey800
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                navigationBar

                VStack(alignment: .leading, spacing: 28) {
                    inputSection(
                        title: "시나리오 제목",
                        placeholder: "예: 엄마와의 대화",
                        text: $title
                    )

                    inputSection(
                        title: "발화자",
                        placeholder: "예: 엄마",
                        text: $callerName
                    )
                }

                Spacer()

                Button {
                    saveScenarioInfo()
                } label: {
                    Text("수정하기")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? Constants.main500 : Constants.main500.opacity(0.24))
                        .cornerRadius(16)
                }
                .disabled(!isFormValid)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 32)
        }
        .navigationBarBackButtonHidden(true)
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
        }
    }

    private func inputSection(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.custom("Pretendard", size: 14).weight(.medium))
                .foregroundColor(Constants.grey300)

            TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.16)))
                .font(.custom("Pretendard", size: 16))
                .foregroundColor(.white)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(Constants.grey700)
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

        do {
            try modelContext.save()
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

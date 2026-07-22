//
//  ScenarioSelectionSheetView.swift
//  Talkie
//
//  Created by DS on 7/22/26.
//

import SwiftUI

struct ScenarioSelectionSheetView: View {
    let scenarios: [Scenario]
    let currentScenario: Scenario?
    let onSelect: (Scenario) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedScenario: Scenario?

    init(
        scenarios: [Scenario],
        currentScenario: Scenario?,
        onSelect: @escaping (Scenario) -> Void
    ) {
        self.scenarios = scenarios
        self.currentScenario = currentScenario
        self.onSelect = onSelect
        _selectedScenario = State(initialValue: currentScenario ?? scenarios.first)
    }

    var body: some View {
        ZStack {
            Constants.grey800
                .ignoresSafeArea()

            VStack(spacing: 24) {
                dragHandle

                Text("통화용 오디오")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                scenarioList

                Button {
                    guard let selectedScenario else {
                        return
                    }

                    onSelect(selectedScenario)
                    dismiss()
                } label: {
                    Text("선택하기")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(selectedScenario == nil ? Constants.main500.opacity(0.24) : Constants.main500)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .disabled(selectedScenario == nil)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
    }

    private var dragHandle: some View {
        Capsule()
            .fill(Color.white.opacity(0.22))
            .frame(width: 48, height: 5)
            .padding(.top, 4)
    }

    @ViewBuilder
    private var scenarioList: some View {
        if scenarios.isEmpty {
            ContentUnavailableView(
                "저장된 시나리오가 없습니다",
                systemImage: "phone.down",
                description: Text("시나리오 탭에서 먼저 대화를 생성해 주세요.")
            )
            .foregroundStyle(.white.opacity(0.72))
            .frame(maxWidth: .infinity, minHeight: 220)
        } else {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(scenarios) { scenario in
                        scenarioRow(scenario)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func scenarioRow(_ scenario: Scenario) -> some View {
        Button {
            selectedScenario = scenario
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(scenario.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("발화자 | \(scenario.callerName)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.42))
                        .lineLimit(1)
                }

                Spacer()

                selectionIndicator(isSelected: selectedScenario === scenario)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background(Constants.grey700)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(scenario.title), 발화자 \(scenario.callerName)")
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(
                    isSelected ? Constants.main500 : Color.white.opacity(0.10),
                    lineWidth: isSelected ? 3 : 0
                )
                .background {
                    Circle()
                        .fill(isSelected ? Color.clear : Color.black.opacity(0.28))
                }
                .frame(width: 22, height: 22)
        }
    }
}

#Preview {
    let scenario = Scenario(title: "기본 제공 시나리오 제목", callerName: "엄마")
    let customScenario = Scenario(title: "생성한 시나리오", callerName: "엄마")

    ScenarioSelectionSheetView(
        scenarios: [scenario, customScenario],
        currentScenario: scenario,
        onSelect: { _ in }
    )
}

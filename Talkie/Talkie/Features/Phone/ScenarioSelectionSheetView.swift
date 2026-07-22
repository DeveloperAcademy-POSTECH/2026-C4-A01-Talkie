//
//  ScenarioSelectionSheetView.swift
//  Talkie
//
//  Created by DS on 7/22/26.
//

import SwiftUI

struct ScenarioSelectionSheetView: View {
    let scenarios: [ScenarioContent]
    let currentScenario: ScenarioContent
    let onSelect: (ScenarioContent) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedScenarioID: ScenarioReference

    init(
        scenarios: [ScenarioContent],
        currentScenario: ScenarioContent,
        onSelect: @escaping (ScenarioContent) -> Void
    ) {
        self.scenarios = scenarios
        self.currentScenario = currentScenario
        self.onSelect = onSelect
        _selectedScenarioID = State(initialValue: currentScenario.id)
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
                    guard let selectedScenario = scenarios.first(where: {
                        $0.id == selectedScenarioID
                    }) else {
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
                        .background(Constants.main500)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
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

    private var scenarioList: some View {
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

    private func scenarioRow(_ scenario: ScenarioContent) -> some View {
        Button {
            selectedScenarioID = scenario.id
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

                selectionIndicator(isSelected: selectedScenarioID == scenario.id)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background(Constants.grey700)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(scenario.title), 발화자 \(scenario.callerName)")
        .accessibilityValue(selectedScenarioID == scenario.id ? "선택됨" : "선택 안 됨")
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
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

#Preview {
    let scenarios = PresetScenarioCatalog.all.map(\.content)
    ScenarioSelectionSheetView(
        scenarios: scenarios,
        currentScenario: PresetScenarioCatalog.kevin.content,
        onSelect: { _ in }
    )
}

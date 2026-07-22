//
//  ScenarioSeedService.swift
//  Talkie
//
//  Created by DS on 7/17/26.
//

import Foundation
import SwiftData

enum ScenarioSeedService {
    /// #54 이전 버전이 SwiftData에 복사한 프리셋을 제거하고 선택값만 새 저장소로 옮깁니다.
    /// 새 프리셋은 PresetScenarioCatalog에서 직접 읽으므로 더 이상 seed하지 않습니다.
    @MainActor
    static func migrateLegacyPresetDataIfNeeded(into modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<Scenario>(
            sortBy: [
                SortDescriptor(\Scenario.createdAt, order: .reverse)
            ]
        )
        let savedScenarios = try modelContext.fetch(descriptor)
        var needsSave = false

        if !ScenarioSelectionStore.hasStoredSelection {
            if let selectedCustomScenario = savedScenarios.first(where: {
                $0.isCurrentSelection && $0.presetID == nil
            }) {
                ScenarioSelectionStore.save(
                    ScenarioReference(
                        source: .custom,
                        scenarioID: selectedCustomScenario.id.uuidString
                    )
                )
            } else {
                ScenarioSelectionStore.resetToDefault()
            }
        }

        for scenario in savedScenarios {
            if scenario.presetID != nil {
                // 이전 seed 프리셋에는 사용자 녹음이 없으므로 SwiftData 객체만 제거합니다.
                modelContext.delete(scenario)
                needsSave = true
            } else if scenario.isCurrentSelection {
                // 선택의 단일 원본은 ScenarioSelectionStore이며 이 플래그는 더 이상 사용하지 않습니다.
                scenario.isCurrentSelection = false
                needsSave = true
            }
        }

        if needsSave {
            try modelContext.save()
        }
    }
}

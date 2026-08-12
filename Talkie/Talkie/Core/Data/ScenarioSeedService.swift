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

/// SwiftData 정리는 UI용 mainContext와 분리된 직렬 executor에서 수행합니다.
/// ModelContext를 detached task로 직접 전달하지 않고 ModelActor가 소유하게 해
/// SwiftData 모델의 실행 격리를 보장합니다.
actor ScenarioMigrationActor: ModelActor {
    nonisolated let modelContainer: ModelContainer
    nonisolated let modelExecutor: any ModelExecutor

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        let modelContext = ModelContext(modelContainer)
        modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
    }

    func migrateLegacyPresetData() throws {
        try ScenarioSeedService.migrateLegacyPresetDataIfNeeded(into: modelContext)
    }
}

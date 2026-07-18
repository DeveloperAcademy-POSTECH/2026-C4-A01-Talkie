//
//  ScenarioSeedService.swift
//  Talkie
//
//  Created by DS on 7/17/26.
//

import Foundation
import SwiftData

enum ScenarioSeedService {
    static func insertDefaultScenariosIfNeeded(into modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<Scenario>(
            sortBy: [
                SortDescriptor(\Scenario.createdAt, order: .reverse)
            ]
        )
        var savedScenarios = try modelContext.fetch(descriptor)
        let savedPresetIDs = Set(savedScenarios.compactMap(\.presetID))
        
        var needsSave = false
        
        for preset in ScenarioPreset.all where !savedPresetIDs.contains(preset.id) {
            let callerProfile = CallerProfile(name: preset.callerName)
            let scenario = Scenario(
                title: preset.title,
                callerProfile: callerProfile,
                presetID: preset.id
            )
            
            let scriptLines = preset.scriptLines.enumerated().map { index, text in
                ScriptLine(
                    text: text,
                    sortOrder: index,
                    scenario: scenario
                )
            }
            
            scenario.scriptLines = scriptLines
            modelContext.insert(scenario)
            savedScenarios.append(scenario)
            needsSave = true
        }
        
        if !savedScenarios.contains(where: \.isCurrentSelection),
           let defaultScenario = savedScenarios.first {
            // 아직 현재 선택된 시나리오가 없다면, 가장 최근 시나리오를 Phone 탭 기본 카드로 사용합니다.
            defaultScenario.isCurrentSelection = true
            needsSave = true
        }
        
        if needsSave {
            try modelContext.save()
        }
    }
}

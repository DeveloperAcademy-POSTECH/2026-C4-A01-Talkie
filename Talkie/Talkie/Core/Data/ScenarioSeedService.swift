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
        let descriptor = FetchDescriptor<Scenario>()
        let savedScenarios = try modelContext.fetch(descriptor)
        let savedPresetIDs = Set(savedScenarios.compactMap(\.presetID))
        
        var didInsertScenario = false
        
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
            didInsertScenario = true
        }
        
        if didInsertScenario {
            try modelContext.save()
        }
    }
}

//
//  ScenarioCreateViewModel.swift
//  Talkie
//
//  Created by DS on 7/18/26.
//

import Foundation
import Observation
import SwiftData

@Observable
final class ScenarioCreateViewModel {
    var scenarioTitle: String = ""
    var callerName: String = ""
    var createdScenario: Scenario?
    var shouldNavigateToScriptEdit: Bool = false
    var errorMessage: String?
    
    var isFormValid: Bool {
        !trimmedScenarioTitle.isEmpty && !trimmedCallerName.isEmpty
    }
    
    func saveInitialScenario(modelContext: ModelContext) {
        guard isFormValid else {
            errorMessage = "시나리오 제목과 발화자를 모두 입력해주세요."
            return
        }
        
        let scenario = Scenario(title: trimmedScenarioTitle, callerName: trimmedCallerName)
        
        let scriptLines = defaultScriptTexts.enumerated().map { index, text in
            ScriptLine(
                text: text,
                sortOrder: index,
                scenario: scenario
            )
        }
        
        scenario.scriptLines = scriptLines
        modelContext.insert(scenario)
        
        do {
            try modelContext.save()
            createdScenario = scenario
            shouldNavigateToScriptEdit = true
        } catch {
            errorMessage = "시나리오를 저장하지 못했습니다."
            print("시나리오 저장 실패: \(error.localizedDescription)")
        }
    }
    
    private var trimmedScenarioTitle: String {
        scenarioTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var trimmedCallerName: String {
        callerName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var defaultScriptTexts: [String] {
        [
            "여보세요?"
        ]
    }
}

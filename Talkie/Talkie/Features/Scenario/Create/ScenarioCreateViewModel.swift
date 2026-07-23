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
    
    func prepareInitialScenario() {
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
        createdScenario = scenario
        shouldNavigateToScriptEdit = true
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

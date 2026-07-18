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
        
        let profile = CallerProfile(name: trimmedCallerName)
        let scenario = Scenario(title: trimmedScenarioTitle, callerProfile: profile)
        
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
            "여보세요?",
            "아직 밖이야? 집에 오는 길 맞지?",
            "내가 맨날 잔소리한다고 하는데 뉴스 보면 별일이 다 있어서 그래.",
            "오늘 뭐 입고 나갔더라? 아침에 정신없이 나가서 기억이 안 나네.",
            "집 거의 다 오면 엄마한테 한 번만 더 전화하거나 문자 보내. 기다리고 있을게."
        ]
    }
}

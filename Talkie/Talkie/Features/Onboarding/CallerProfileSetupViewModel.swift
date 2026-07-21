//
//  CallerProfileSetupViewModel.swift
//  Talkie
//
//  Created by DS on 7/13/26.
//

import Foundation
import Observation
import SwiftData

@Observable
final class CallerProfileSetupViewModel {
    var name: String = ""
    var errorMessage: String?
    
    var isSaveDisabled: Bool {
        trimmedName.isEmpty
    }
    
    func saveProfile(modelContext: ModelContext) {
        errorMessage = nil
        
        guard !trimmedName.isEmpty else {
            errorMessage = "프로필 이름을 입력해 주세요."
            return
        }
        
        let scenario = Scenario(
            title: "\(trimmedName)와의 통화",
            callerName: trimmedName
        )
        
        let presetTexts = scriptPreset()
        let scriptLines = presetTexts.enumerated().map { index, text in
            ScriptLine(
                text: text,
                sortOrder: index,
                scenario: scenario,
                audioMetadata: nil
            )
        }
        
        scenario.scriptLines = scriptLines
        modelContext.insert(scenario)
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func scriptPreset() -> [String] {
        ["어디야?", "거의 다 왔어?", "조심해서 와."]
    }
}

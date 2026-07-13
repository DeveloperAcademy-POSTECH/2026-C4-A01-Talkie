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
    var relationship: String = ""
    var errorMessage: String?
    
    var isSaveDisabled: Bool {
        trimmedName.isEmpty || trimmedRelationship.isEmpty
    }
    
    func saveProfile(modelContext: ModelContext) {
        errorMessage = nil
        
        guard !trimmedName.isEmpty, !trimmedRelationship.isEmpty else {
            errorMessage = "프로필 이름과 관계를 입력해 주세요."
            return
        }
        
        let profile = CallerProfile(
            name: trimmedName,
            relationship: trimmedRelationship
        )
        
        let presetTexts = scriptPreset(for: trimmedRelationship)
        let scriptLines = presetTexts.enumerated().map { index, text in
            ScriptLine(
                text: text,
                sortOrder: index,
                callerProfile: profile
            )
        }
        
        profile.scriptLines = scriptLines
        modelContext.insert(profile)
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var trimmedRelationship: String {
        relationship.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func scriptPreset(for relationship: String) -> [String] {
        let presets: [String: [String]] = [
            "가족": ["어디야?", "거의 다 왔어?", "조심해서 와."],
            "친구": ["언제 와?", "기다리고 있어.", "빨리 와!"],
            "연인": ["어디쯤이야?", "보고 싶어.", "조심해서 오구!"]
        ]
        
        return presets[relationship] ?? ["여보세요?", "지금 통화 가능해?", "나중에 다시 연락줘."]
    }
}

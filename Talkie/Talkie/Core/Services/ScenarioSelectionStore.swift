//
//  ScenarioSelectionStore.swift
//  Talkie
//
//  Created for issue #54.
//

import Foundation

/// 현재 통화에 사용할 시나리오의 참조만 저장합니다.
/// 프리셋 데이터 자체는 Bundle에, 사용자 시나리오는 SwiftData에 남겨 저장 책임을 섞지 않습니다.
@MainActor
enum ScenarioSelectionStore {
    private static let sourceKey = "scenario.selection.source"
    private static let identifierKey = "scenario.selection.identifier"

    static var hasStoredSelection: Bool {
        defaults.string(forKey: sourceKey) != nil
            && defaults.string(forKey: identifierKey) != nil
    }

    static func load() -> ScenarioReference {
        guard let sourceValue = defaults.string(forKey: sourceKey),
              let source = ScenarioSource(rawValue: sourceValue),
              let scenarioID = defaults.string(forKey: identifierKey),
              !scenarioID.isEmpty else {
            return .defaultPreset
        }

        let reference = ScenarioReference(source: source, scenarioID: scenarioID)
        guard isStructurallyValid(reference) else {
            return .defaultPreset
        }
        return reference
    }

    static func save(_ reference: ScenarioReference) {
        defaults.set(reference.source.rawValue, forKey: sourceKey)
        defaults.set(reference.scenarioID, forKey: identifierKey)
    }

    static func resetToDefault() {
        save(.defaultPreset)
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: WidgetScenarioStore.appGroupID) ?? .standard
    }

    private static func isStructurallyValid(_ reference: ScenarioReference) -> Bool {
        switch reference.source {
        case .preset:
            PresetScenarioID(rawValue: reference.scenarioID) != nil
        case .custom:
            UUID(uuidString: reference.scenarioID) != nil
        }
    }
}

//
//  ScenarioContent.swift
//  Talkie
//
//  Created for issue #54.
//

import Foundation

enum ScenarioSource: String, Codable, Hashable, Sendable {
    case preset
    case custom
}

/// 프리셋과 사용자 시나리오를 동일한 화면에서 선택하기 위한 안정적인 참조입니다.
struct ScenarioReference: Codable, Hashable, Sendable {
    let source: ScenarioSource
    let scenarioID: String

    static let defaultPreset = ScenarioReference(
        source: .preset,
        scenarioID: PresetScenarioCatalog.defaultPresetID.rawValue
    )
}

/// 오디오가 저장된 위치만 표현합니다. 실제 URL 해석은 ScenarioAudioResolver의 책임입니다.
enum ScenarioAudioSource: Hashable, Sendable {
    case bundled(
        resourceName: String,
        resourceExtension: String,
        subdirectory: String
    )
    case documents(fileName: String)
}

/// 목록, 상세, 선택 화면과 가상 통화가 공통으로 사용하는 문장 값입니다.
struct ScenarioLineContent: Identifiable, Hashable, Sendable {
    let id: String
    let sortOrder: Int
    let text: String
    let audioSource: ScenarioAudioSource?
}

/// 저장 방식과 무관하게 시나리오를 읽기 위한 불변 스냅숏입니다.
/// SwiftUI 화면과 통화 상태 머신에 SwiftData 모델을 직접 넘기지 않도록 경계를 만듭니다.
struct ScenarioContent: Identifiable, Hashable, Sendable {
    let id: ScenarioReference
    let title: String
    let callerName: String
    let scriptLines: [ScenarioLineContent]

    var isPreset: Bool {
        id.source == .preset
    }

    var scriptPreview: String {
        let text = scriptLines
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.text)
            .joined(separator: " / ")
        return text.isEmpty ? "등록된 시나리오 내용이 없습니다." : text
    }
}

extension PresetScenario {
    var content: ScenarioContent {
        ScenarioContent(
            id: ScenarioReference(source: .preset, scenarioID: id.rawValue),
            title: title,
            callerName: callerName,
            scriptLines: scriptLines.map { line in
                ScenarioLineContent(
                    id: line.id,
                    sortOrder: line.sortOrder,
                    text: line.text,
                    audioSource: .bundled(
                        resourceName: line.audioResourceName,
                        resourceExtension: line.audioResourceExtension,
                        subdirectory: line.audioSubdirectory
                    )
                )
            }
        )
    }
}

extension Scenario {
    var content: ScenarioContent {
        ScenarioContent(
            id: ScenarioReference(source: .custom, scenarioID: id.uuidString),
            title: title,
            callerName: callerName,
            scriptLines: scriptLines.map { line in
                ScenarioLineContent(
                    id: line.id.uuidString,
                    sortOrder: line.sortOrder,
                    text: line.text,
                    audioSource: line.isRecorded
                        ? line.audioFileName.map(ScenarioAudioSource.documents)
                        : nil
                )
            }
        )
    }
}

@MainActor
enum ScenarioLibrary {
    static func all(customScenarios: [Scenario]) -> [ScenarioContent] {
        let presets = PresetScenarioCatalog.all
            .sorted { $0.displayOrder < $1.displayOrder }
            .map(\.content)
        return presets + customScenarios.map(\.content)
    }

    static func resolve(
        _ reference: ScenarioReference,
        customScenarios: [Scenario]
    ) -> ScenarioContent? {
        switch reference.source {
        case .preset:
            guard let presetID = PresetScenarioID(rawValue: reference.scenarioID) else {
                return nil
            }
            return PresetScenarioCatalog.preset(for: presetID)?.content
        case .custom:
            guard let scenarioID = UUID(uuidString: reference.scenarioID) else {
                return nil
            }
            return customScenarios.first { $0.id == scenarioID }?.content
        }
    }
}

//
//  PresetScenario.swift
//  Talkie
//
//  Created for issue #54.
//

import Foundation

/// 앱이 제공하는 읽기 전용 시나리오의 안정적인 식별자입니다.
/// 표시 문자열 대신 이 값을 저장하므로 제목이 바뀌어도 선택 상태를 복원할 수 있습니다.
enum PresetScenarioID: String, CaseIterable, Codable, Hashable, Sendable {
    case grace
    case kaelyn
    case kevin
}

/// 앱 번들에 포함된 문장 하나와 대응 음원을 설명하는 불변 값입니다.
/// 실제 오디오 Data나 URL은 보관하지 않고, 재생 시 Bundle에서 찾을 수 있는 키만 가집니다.
struct PresetScriptLine: Identifiable, Hashable, Sendable {
    let id: String
    let sortOrder: Int
    let text: String
    let audioResourceName: String
    let audioResourceExtension: String
    let audioSubdirectory: String
}

/// SwiftData에 저장하지 않는 앱 기본 시나리오입니다.
/// 모든 속성을 let으로 유지해 편집·삭제·재녹음 대상이 아님을 타입 수준에서 표현합니다.
struct PresetScenario: Identifiable, Hashable, Sendable {
    let id: PresetScenarioID
    let displayOrder: Int
    let title: String
    let callerName: String
    let scriptLines: [PresetScriptLine]
}

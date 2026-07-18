//
//  ScenarioPreset.swift
//  Talkie
//
//  Created by DS on 7/17/26.
//

struct ScenarioPreset {
    let id: String
    let title: String
    let callerName: String
    let scriptLines: [String]
}

extension ScenarioPreset {
    static let momCall = ScenarioPreset(
        id: "preset_default_scenario_01",
        title: "기본 제공 시나리오 제목",
        callerName: "사용자 설정 이름",
        scriptLines: [
            "시나리오 내용 첫 문장",
            "시나리오 두 번째 문장",
            "시나리오 세 번째 문장",
            "시나리오 네 번째 문장",
            "시나리오 다섯 번째 문장"
        ]
    )
    
    static let all: [ScenarioPreset] = [
        momCall
    ]
}


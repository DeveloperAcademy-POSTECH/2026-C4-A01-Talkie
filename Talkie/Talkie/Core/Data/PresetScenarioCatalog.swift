//
//  PresetScenarioCatalog.swift
//  Talkie
//
//  Created for issue #54.
//

import Foundation

/// 앱 기본 프리셋의 유일한 원본입니다.
/// Markdown은 제작 자료로만 사용하고, 앱 실행 중에는 이 검증된 manifest를 읽습니다.
enum PresetScenarioCatalog {
    static let defaultPresetID: PresetScenarioID = .kevin

    static let grace = makePreset(
        id: .grace,
        displayOrder: 0,
        title: "Grace와의 통화",
        callerName: "Grace",
        audioPrefix: "Grace",
        scriptLines: graceAndKaelynScript
    )

    static let kaelyn = makePreset(
        id: .kaelyn,
        displayOrder: 1,
        title: "Kaelyn과의 통화",
        callerName: "Kaelyn",
        audioPrefix: "Kaelyn",
        scriptLines: graceAndKaelynScript
    )

    static let kevin = makePreset(
        id: .kevin,
        displayOrder: 2,
        title: "Kevin과의 통화",
        callerName: "Kevin",
        audioPrefix: "Kevin",
        scriptLines: kevinScript
    )

    static let all: [PresetScenario] = [grace, kaelyn, kevin]

    static func preset(for id: PresetScenarioID) -> PresetScenario? {
        all.first { $0.id == id }
    }

    private static func makePreset(
        id: PresetScenarioID,
        displayOrder: Int,
        title: String,
        callerName: String,
        audioPrefix: String,
        scriptLines: [String]
    ) -> PresetScenario {
        let lines = scriptLines.enumerated().map { index, text in
            let number = String(format: "%02d", index + 1)
            return PresetScriptLine(
                id: "\(id.rawValue)-\(number)",
                sortOrder: index,
                text: text,
                audioResourceName: "\(audioPrefix)_\(number)",
                audioResourceExtension: "m4a",
                audioSubdirectory: "Presets/\(audioPrefix)"
            )
        }

        return PresetScenario(
            id: id,
            displayOrder: displayOrder,
            title: title,
            callerName: callerName,
            scriptLines: lines
        )
    }

    private static let graceAndKaelynScript = [
        "여보세요.",
        "이제 집 가는 중이야?",
        "오늘 생각보다 늦었네. 나도 집 가다가 갑자기 생각나서 전화했어.",
        "지금 어디쯤이야?",
        "아 거기면 이제 거의 다 왔네.",
        "안피곤해?",
        "아 더워. 요즘 날씨가 오락가락 거려서 넌 뭐 입고 다녀?",
        "아 근데 이 시간에 주변에 사람들은 좀 지나가?",
        "그래도 너무 어두운 골목은 들어가지 말고.",
        "집까지 얼마나 남았어?",
        "오 그럼 진짜 얼마 안 남았네.",
        "도착하면 카톡 하나만 남겨줘.",
        "조심해서 들어가."
    ]

    private static let kevinScript = [
        "여보세요,",
        "이제 집 가는 중이지?",
        "오늘 얼굴도 제대로 못 봤네.",
        "피곤하지?",
        "지금 밖에 어때? 오늘 날씨 어땠어?",
        "주변에 사람 좀 있어?",
        "지금 어디쯤인지 맞혀볼까?",
        "혹시 서울역 지나고 있어?",
        "맞췄네.",
        "아니야?",
        "응 그래.",
        "오늘 뭐 입었는지 사진 보내준다더니 까먹었어?",
        "그럼 뭐 입었는지 말해죵",
        "뭐야, 그러면?",
        "그럼 뭐 입었는지 말해줘.",
        "그럼 뭐 입었는지 말해줘.",
        "아 그래?",
        "배터리는 괜찮아?",
        "난 15%밖에 안남았네",
        "아 그럼 영상통화는 집 가서 하자~ 걸어가면서 하지 말고.",
        "이제 집까지 몇 분 정도 남았어?",
        "오 금방이네~",
        "그럼 나 씻고 기다리고 있을게. 도착하면 문 앞에서 전화 한 번만 해줘!",
        "들어가."
    ]
}

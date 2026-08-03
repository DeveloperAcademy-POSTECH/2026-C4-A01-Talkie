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
        scriptLines: graceScript
    )

    static let kaelyn = makePreset(
        id: .kaelyn,
        displayOrder: 1,
        title: "Kaelyn과의 통화",
        callerName: "Kaelyn",
        audioPrefix: "Kaelyn",
        scriptLines: kaelynScript
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

    private static let graceScript = [
        "여보세요.",
        "이제 집 가는 중이야?",
        "오늘 좀 늦네. 나도 집 가다가 갑자기 심심해서 전화했어.",
        "지금 어디쯤 왔어?",
        "오 그쪽이면 이제 거의 다 왔네.",
        "오늘 날씨가 너무 이상해. 어땠어?",
        "주변에 사람들은 좀 있어?",
        "너무 한적한 길로 다니지 말고 큰 길로 다니고",
        "우리 엄마도 맨날 잔소리하는데 뉴스보면 별일이 다 있더라고",
        "혼자면 이어폰 너무 크게 듣지말고, 주변도 좀 보면서 걷고",
        "핸드폰 배터리는 괜찮아?",
        "배터리없다고 중간에 끊기면 괜히 또 걱정하쟎아.",
        "집까지는 얼마나 남았어?",
        "오 거의 다왔네.",
        "그래도 다음부터 너무 늦으면 그냥 택시 타.",
        "몇천원 아끼려다가 괜히 위험하면 안돼쟎아.",
        "알겠지?",
        "조심히 들어가고 집 도착하면 문자 하나만 남겨줘.",
        "응"
    ]

    private static let kaelynScript = [
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
        "오늘 뭐 입었는지 말 해준다더니 까먹었어?",
        "그럼 지금 뭐 입었는지 말해죵",
        "배터리는 괜찮아?",
        "아 그럼 영상통화는 집 가서 하자~걸어가면서 하지 말고.",
        "이제 집까지 몇 분 정도 남았어?",
        "오 금방이네~",
        "그럼 나 씻고 기다리고 있을게.",
        "이따가 도착하면 문 앞에서 전화 한 번만 해줘!"
    ]
}

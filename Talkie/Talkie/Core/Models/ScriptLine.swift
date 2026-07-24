//
//  ScriptLine.swift
//  Talkie
//
//  Created by DS on 7/13/26.
//

import Foundation
import SwiftData

@Model
final class ScriptLine {
    /// 사용자 시나리오 문장을 화면·통화 스냅숏에서 안정적으로 식별합니다.
    var id: UUID = UUID()
    var text: String
    var sortOrder: Int
    var isRecorded: Bool
    var audioFileName: String?
    /// 대사와 연결된 녹음 파일의 마지막 변경 시각입니다.
    var updatedAt: Date = Date()
    var scenario: Scenario?
    
    @Relationship(deleteRule: .cascade, inverse: \AudioClipMetadata.scriptLine)
    var audioMetadata: AudioClipMetadata?
    
    init(
        id: UUID = UUID(),
        text: String,
        sortOrder: Int,
        isRecorded: Bool = false,
        audioFileName: String? = nil,
        updatedAt: Date = Date(),
        scenario: Scenario?,
        audioMetadata: AudioClipMetadata? = nil
    ) {
        self.id = id
        self.text = text
        self.sortOrder = sortOrder
        self.isRecorded = isRecorded
        self.audioFileName = audioFileName
        self.updatedAt = updatedAt
        self.scenario = scenario
        self.audioMetadata = audioMetadata
    }
}

//
//  Scenario.swift
//  Talkie
//
//  Created by DS on 7/13/26.
//
import Foundation
import SwiftData

@Model
final class Scenario {
    /// 사용자 생성 시나리오를 선택 저장소에서 안정적으로 다시 찾기 위한 ID입니다.
    var id: UUID = UUID()
    var title: String
    var createdAt: Date
    /// 로컬 변경과 iCloud 변경이 충돌할 때 더 최신 값을 고르기 위한 시각입니다.
    var updatedAt: Date = Date()
    /// #54 이전 seed 데이터를 한 번 정리하기 위한 임시 호환 필드입니다.
    /// 새 프리셋은 이 모델에 저장하지 않습니다.
    var presetID: String?
    /// #54 이전 선택값을 새 ScenarioSelectionStore로 옮기기 위한 임시 호환 필드입니다.
    var isCurrentSelection: Bool
    var callerName: String
    
    @Relationship(deleteRule: .cascade, inverse: \ScriptLine.scenario)
    var scriptLines: [ScriptLine] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        callerName: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        presetID: String? = nil,
        isCurrentSelection: Bool = false
    ) {
        self.id = id
        self.title = title
        self.callerName = callerName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.presetID = presetID
        self.isCurrentSelection = isCurrentSelection
    }
    
//    @Relationship(deleteRule: .cascade, inverse: \CallReservation.scenario)
//    var reservations: [CallReservation] = []
// scheduledDate: Date? - 백그라운드 로컬 알림을 등록할 때 있는 편이 남은 시간을 계산하기 수월하기 때문에 보류
    

}

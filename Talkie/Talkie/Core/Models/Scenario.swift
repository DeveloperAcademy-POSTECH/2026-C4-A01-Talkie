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
    var title: String
    var createdAt: Date
    var presetID: String?
    var isCurrentSelection: Bool
    var callerName: String
    
    @Relationship(deleteRule: .cascade, inverse: \ScriptLine.scenario)
    var scriptLines: [ScriptLine] = []
    
    init(
        title: String,
        callerName: String,
        createdAt: Date = Date(),
        presetID: String? = nil,
        isCurrentSelection: Bool = false
    ) {
        self.title = title
        self.callerName = callerName
        self.createdAt = createdAt
        self.presetID = presetID
        self.isCurrentSelection = isCurrentSelection
    }
    
//    @Relationship(deleteRule: .cascade, inverse: \CallReservation.scenario)
//    var reservations: [CallReservation] = []
// scheduledDate: Date? - 백그라운드 로컬 알림을 등록할 때 있는 편이 남은 시간을 계산하기 수월하기 때문에 보류
    

}

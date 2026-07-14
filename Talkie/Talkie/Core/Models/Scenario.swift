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
    
    @Relationship(deleteRule: .cascade)
    var callerProfile: CallerProfile
    
    @Relationship(deleteRule: .cascade, inverse: \ScriptLine.scenario)
    var scriptLines: [ScriptLine] = []
    
    @Relationship(deleteRule: .cascade, inverse: \CallReservation.scenario)
    var reservations: [CallReservation] = []
    
    // scheduledDate: Date? - 백그라운드 로컬 알림을 등록할 때 있는 편이 남은 시간을 계산하기 수월하기 때문에 보류
    
    init(title: String, callerProfile: CallerProfile) {
        self.title = title
        self.callerProfile = callerProfile
    }
}

//
//  CallReservation.swift
//  Talkie
//
//  Created by DS on 7/14/26.
//

import Foundation
import SwiftData

@Model
final class CallReservation {
    var delaySeconds: Int
    var scheduledDate: Date?
    var createdAt: Date
    var status: String
    var scenario: Scenario?
    
    init(
        delaySeconds: Int = 0,
        scheduledDate: Date? = nil,
        createdAt: Date = .now,
        status: String = "pending",
        scenario: Scenario? = nil
    ) {
        self.delaySeconds = delaySeconds
        self.scheduledDate = scheduledDate
        self.createdAt = createdAt
        self.status = status
        self.scenario = scenario
    }
}

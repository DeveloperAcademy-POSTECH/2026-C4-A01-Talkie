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
    
    @Relationship(deleteRule: .cascade, inverse: \CallerProfile.scenario)
    var callerProfile: CallerProfile?
    
    @Relationship(deleteRule: .cascade, inverse: \ScriptLine.scenario)
    var scriptLines: [ScriptLine] = []
    
    init(
        title: String,
        createdAt: Date = Date(),
        callerProfile: CallerProfile? = nil,
        scriptLines: [ScriptLine] = []
    ) {
        self.title = title
        self.createdAt = createdAt
        self.callerProfile = callerProfile
        self.scriptLines = scriptLines
    }
}

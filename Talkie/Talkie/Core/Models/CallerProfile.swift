//
//  CallerProfile.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import Foundation
import SwiftData

@Model
final class CallerProfile {
    var name: String         // 예: "엄마"
    var relationship: String // 예: "가족"
    
    @Relationship(deleteRule: .cascade, inverse: \ScriptLine.callerProfile) // 프로필 삭제 시 속한 ScriptLine들도 함께 자동 삭제 (Cascade)
    var scriptLines: [ScriptLine] = []
    
    init(name: String, relationship: String) {
        self.name = name
        self.relationship = relationship
    }
}

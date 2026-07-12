//
//  ScriptLine.swift
//  Talkie
//
//  Created by DS on 7/13/26.
//

import Foundation
import SwiftData

@Model
final class ScriptLine { //final을 사용한 이유 -
    var text: String
    var sortOrder: Int
    
    var callerProfile: CallerProfile
    
    init(text: String, sortOrder: Int, callerProfile: CallerProfile) {
        self.text = text
        self.sortOrder = sortOrder
        self.callerProfile = callerProfile
    }
}

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
    
    init(name: String, relationship: String) {
        self.name = name
        self.relationship = relationship
    }
}

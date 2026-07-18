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
    var text: String
    var sortOrder: Int
    var isRecorded: Bool
    var scenario: Scenario?
    
    @Relationship(deleteRule: .cascade, inverse: \AudioClipMetadata.scriptLine)
    var audioMetadata: AudioClipMetadata?
    
    init(
        text: String,
        sortOrder: Int,
        isRecorded: Bool = false,
        scenario: Scenario?,
        audioMetadata: AudioClipMetadata? = nil
    ) {
        self.text = text
        self.sortOrder = sortOrder
        self.isRecorded = isRecorded
        self.scenario = scenario
        self.audioMetadata = audioMetadata
    }
}

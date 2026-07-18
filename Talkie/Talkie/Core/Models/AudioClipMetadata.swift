//
//  AudioClipMetadata.swift
//  Talkie
//
//  Created by DS on 7/13/26.
//

import Foundation
import SwiftData

@Model
final class AudioClipMetadata {
    var fileName: String
    var relativePath: String
    var duration: Double
    var createdAt: Date
    
    @Attribute(.externalStorage)
    var audioData: Data?
    
    var scriptLine: ScriptLine?
    
    init(
        fileName: String,
        relativePath: String,
        duration: Double = 0.0,
        createdAt: Date = Date(),
        audioData: Data? = nil,
        scriptLine: ScriptLine? = nil
    ) {
        self.fileName = fileName
        self.relativePath = relativePath
        self.duration = duration
        self.createdAt = createdAt
        self.audioData = audioData
        self.scriptLine = scriptLine
    }
}

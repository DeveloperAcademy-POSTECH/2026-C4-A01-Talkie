//
//  CallRecording.swift
//  Talkie
//

import Foundation
import SwiftData

/// 통화 녹음 파일의 위치와 재생에 필요한 메타데이터를 저장합니다.
/// 오디오 원본은 SwiftData가 아니라 Documents/CallRecordings에 보관합니다.
@Model
final class CallRecording {
    var id: UUID
    var fileName: String
    var duration: TimeInterval
    var fileSize: Int64
    var createdAt: Date
    var session: CallSession?

    init(
        id: UUID = UUID(),
        fileName: String,
        duration: TimeInterval,
        fileSize: Int64,
        createdAt: Date = Date(),
        session: CallSession? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.duration = duration
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.session = session
    }
}

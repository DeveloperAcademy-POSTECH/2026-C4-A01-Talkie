//
//  CallSession.swift
//  Talkie
//

import Foundation
import SwiftData

/// 한 번의 가상 통화 실행을 나타냅니다.
///
/// 시나리오나 발신자 정보가 나중에 수정되더라도 과거 내역이 바뀌지 않도록
/// 통화 당시의 제목과 발신자 이름을 문자열 스냅샷으로 저장합니다.
@Model
final class CallSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date
    var scenarioTitle: String
    var callerName: String
    var endReasonRawValue: String

    /// 세션을 삭제하면 연결된 녹음 메타데이터도 함께 삭제합니다.
    /// 실제 오디오 파일 삭제는 `CallRecordingFileStore`가 담당합니다.
    @Relationship(deleteRule: .cascade, inverse: \CallRecording.session)
    var recording: CallRecording?

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        scenarioTitle: String,
        callerName: String,
        endReason: CallEndReason,
        recording: CallRecording? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.scenarioTitle = scenarioTitle
        self.callerName = callerName
        endReasonRawValue = endReason.rawValue
        self.recording = recording
    }

    var endReason: CallEndReason {
        get { CallEndReason(rawValue: endReasonRawValue) ?? .unknown }
        set { endReasonRawValue = newValue.rawValue }
    }
}

enum CallEndReason: String, Codable, Sendable {
    case userEnded
    case completed
    case interrupted
    case failed
    case unknown
}

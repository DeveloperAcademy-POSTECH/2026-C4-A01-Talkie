//
//  CallSessionStore.swift
//  Talkie
//

import SwiftData

/// 완료된 통화 결과를 SwiftData 모델로 변환하고 저장합니다.
/// 저장 실패 시 고아 녹음 파일을 정리하고 context를 이전 상태로 되돌립니다.
@MainActor
struct CallSessionStore {
    private let recordingFileStore: CallRecordingFileStore

    init(recordingFileStore: CallRecordingFileStore = CallRecordingFileStore()) {
        self.recordingFileStore = recordingFileStore
    }

    func save(
        _ completedSession: CompletedFakeCallSession,
        in modelContext: ModelContext
    ) throws {
        let recording = completedSession.recording.map {
            CallRecording(
                fileName: $0.fileName,
                duration: $0.duration,
                fileSize: $0.fileSize,
                createdAt: $0.createdAt
            )
        }
        let session = CallSession(
            startedAt: completedSession.startedAt,
            endedAt: completedSession.endedAt,
            scenarioTitle: completedSession.scenarioTitle,
            callerName: completedSession.callerName,
            endReason: completedSession.endReason,
            recording: recording
        )
        recording?.session = session
        modelContext.insert(session)

        do {
            try modelContext.save()
        } catch {
            if let recording {
                try? recordingFileStore.delete(fileName: recording.fileName)
            }
            modelContext.rollback()
            throw error
        }
    }
}

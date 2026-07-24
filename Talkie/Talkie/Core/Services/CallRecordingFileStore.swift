//
//  CallRecordingFileStore.swift
//  Talkie
//

import Foundation

/// 통화 녹음 파일의 실제 저장 위치를 관리합니다.
///
/// SwiftData에는 샌드박스 절대 경로가 아닌 `fileName`만 저장합니다. 앱 컨테이너의
/// 절대 경로는 설치할 때마다 달라질 수 있으므로 재생·삭제 시점에 URL을 다시 만듭니다.
nonisolated struct CallRecordingFileStore: Sendable {
    private static let directoryName = "CallRecordings"
    private let baseDirectoryURL: URL?

    init(baseDirectoryURL: URL? = nil) {
        self.baseDirectoryURL = baseDirectoryURL
    }

    func makeFileName() -> String {
        "\(UUID().uuidString).m4a"
    }

    func directoryURL() throws -> URL {
        let fileManager = FileManager.default
        let documentsURL = try baseDirectoryURL ?? fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = documentsURL.appendingPathComponent(
            Self.directoryName,
            isDirectory: true
        )

        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        }
        return directoryURL
    }

    func url(for fileName: String) throws -> URL {
        try directoryURL().appendingPathComponent(fileName, isDirectory: false)
    }

    func fileExists(fileName: String) throws -> Bool {
        FileManager.default.fileExists(atPath: try url(for: fileName).path)
    }

    func fileSize(fileName: String) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(
            atPath: url(for: fileName).path
        )
        return (attributes[.size] as? NSNumber)?.int64Value ?? 0
    }

    func delete(fileName: String) throws {
        let fileManager = FileManager.default
        let fileURL = try url(for: fileName)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }
}

/// 오디오 엔진이 종료된 뒤 SwiftData 모델로 변환할 값만 전달하는 경량 결과입니다.
nonisolated struct CompletedCallRecording: Sendable {
    let fileName: String
    let duration: TimeInterval
    let fileSize: Int64
    let createdAt: Date
}

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
    var id: UUID
    var fileName: String        // 앱 Sandbox Documents 내 실시간 파일명
    var duration: Double        // 재생 시간 (초)
    var fileSize: Int           // 파일 용량 (Bytes)
    var createdAt: Date         // 생성 일시
    var isCloudSynced: Bool     // iCloud 업로드 완료 여부
    
    // ScriptLine과의 역관계 설정 (1:1 또는 1:0)
    var scriptLine: ScriptLine?
    
    init(
        id: UUID = UUID(),
        fileName: String,
        duration: Double = 0.0,
        fileSize: Int = 0,
        createdAt: Date = Date(),
        isCloudSynced: Bool = false
    ) {
        self.id = id
        self.fileName = fileName
        self.duration = duration
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.isCloudSynced = isCloudSynced
    }
    
    /// 로컬 Documents 디렉토리 내의 실제 파일 URL 경로 반환 헬퍼
    var localFileURL: URL? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent(fileName)
    }
}

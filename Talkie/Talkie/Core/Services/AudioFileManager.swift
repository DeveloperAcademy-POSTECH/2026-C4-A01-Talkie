//
//  AudioFileManager.swift
//  Talkie
//
//  Created by DS on 7/18/26.
//

import Foundation

struct AudioFileManager {
    private static let fileManager = FileManager.default
    
    // 앱마다 주어지는 Documents 폴더 URL입니다.
    // 앱 샌드박스 경로는 실행 환경에 따라 바뀔 수 있으므로, 이 URL 자체를 SwiftData에 저장하지 않습니다.
    static var documentsDirectoryURL: URL {
        get throws {
            try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }
    }
    
    // 녹음 파일끼리 이름이 겹치지 않도록 UUID를 사용합니다.
    static func makeFileName() -> String {
        "\(UUID().uuidString).m4a"
    }
    
    // SwiftData에는 fileName만 저장하고, 실제 사용할 때 Documents URL과 다시 합칩니다.
    static func url(for fileName: String) throws -> URL {
        try documentsDirectoryURL.appendingPathComponent(fileName)
    }
    
    static func fileExists(fileName: String) throws -> Bool {
        let fileURL = try url(for: fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    static func delete(fileName: String) throws {
        let fileURL = try url(for: fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        
        try fileManager.removeItem(at: fileURL)
    }
    
    // 재녹음처럼 기존 파일을 새 파일로 바꿔야 할 때 사용합니다.
    static func deleteIfNeeded(fileName: String?) throws {
        guard let fileName else {
            return
        }
        
        try delete(fileName: fileName)
    }
}

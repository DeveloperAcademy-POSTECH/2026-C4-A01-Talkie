//
//  ScenarioAudioResolver.swift
//  Talkie
//
//  Created for issue #54.
//

import Foundation

enum ScenarioAudioResolverError: LocalizedError {
    case bundledAudioMissing(String)
    case customAudioMissing(String)
    case playbackFailed(String)

    var errorDescription: String? {
        switch self {
        case let .bundledAudioMissing(resource):
            "프리셋 음원을 찾을 수 없습니다: \(resource)"
        case let .customAudioMissing(fileName):
            "사용자 녹음 파일을 찾을 수 없습니다: \(fileName)"
        case let .playbackFailed(fileName):
            "음원 파일을 재생할 수 없습니다: \(fileName)"
        }
    }
}

/// ScenarioAudioSource를 실제 재생 URL로 변환하는 유일한 위치입니다.
/// 프리셋은 Bundle, 사용자 녹음은 Documents라는 저장 경계를 이 서비스가 보장합니다.
enum ScenarioAudioResolver {
    static func url(
        for source: ScenarioAudioSource,
        bundle: Bundle = .main
    ) throws -> URL {
        switch source {
        case let .bundled(resourceName, resourceExtension, subdirectory):
            // Xcode의 synchronized group이 폴더 구조를 보존하는 경우를 먼저 찾습니다.
            if let url = bundle.url(
                forResource: resourceName,
                withExtension: resourceExtension,
                subdirectory: subdirectory
            ) {
                return url
            }

            // 빌드 설정이 리소스를 bundle root에 평탄화해도 같은 고유 파일명으로 찾습니다.
            if let url = bundle.url(
                forResource: resourceName,
                withExtension: resourceExtension
            ) {
                return url
            }

            throw ScenarioAudioResolverError.bundledAudioMissing(
                "\(subdirectory)/\(resourceName).\(resourceExtension)"
            )

        case let .documents(fileName):
            guard try AudioFileManager.fileExists(fileName: fileName) else {
                throw ScenarioAudioResolverError.customAudioMissing(fileName)
            }
            return try AudioFileManager.url(for: fileName)
        }
    }
}

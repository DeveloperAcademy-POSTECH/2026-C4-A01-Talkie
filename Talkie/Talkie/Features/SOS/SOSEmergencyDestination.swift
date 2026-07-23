//
//  SOSEmergencyDestination.swift
//  Talkie
//

import Foundation

/// 112 문자/전화 신고 대상을 한 곳에서 결정합니다.
///
/// Debug 빌드는 Xcode Scheme의 Environment Variables에 `TALKIE_SOS_TEST_NUMBER`를
/// 설정하면 해당 테스트 번호를 사용하고, 없으면 실제 서비스 번호인 112를 사용합니다.
/// 문자 전송과 전화 연결은 모두 iOS 시스템 화면에서 사용자가 마지막으로 확인합니다.
enum SOSEmergencyDestination {
    private static let testNumberEnvironmentKey = "TALKIE_SOS_TEST_NUMBER"

    static var phoneNumber: String {
#if DEBUG
        return configuredTestNumber ?? "112"
#else
        return "112"
#endif
    }

    static var displayName: String {
#if DEBUG
        configuredTestNumber.map { "테스트 번호 \($0)" } ?? "112"
#else
        "112"
#endif
    }

    private static var configuredTestNumber: String? {
        guard let rawValue = ProcessInfo.processInfo.environment[
            testNumberEnvironmentKey
        ] else {
            return nil
        }

        return sanitizedPhoneNumber(rawValue)
    }

    private static func sanitizedPhoneNumber(_ value: String) -> String? {
        let compactNumber = value.filter { character in
            character.isNumber || character == "+"
        }
        guard compactNumber.count >= 3 else { return nil }
        return compactNumber
    }
}

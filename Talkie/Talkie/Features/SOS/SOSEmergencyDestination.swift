//
//  SOSEmergencyDestination.swift
//  Talkie
//

import Foundation

/// 개발 중 실제 112로 문자나 전화를 보내지 않도록 신고 대상을 한 곳에서 결정합니다.
///
/// Debug 빌드는 Xcode Scheme의 Environment Variables에 `TALKIE_SOS_TEST_NUMBER`를
/// 설정한 경우에만 신고 흐름을 엽니다. Release 빌드는 최종 서비스 번호인 112를 사용합니다.
enum SOSEmergencyDestination {
    private static let testNumberEnvironmentKey = "TALKIE_SOS_TEST_NUMBER"

    static var phoneNumber: String? {
#if DEBUG
        guard let rawValue = ProcessInfo.processInfo.environment[
            testNumberEnvironmentKey
        ] else {
            return nil
        }
        return sanitizedPhoneNumber(rawValue)
#else
        return "112"
#endif
    }

    static var displayName: String {
#if DEBUG
        phoneNumber.map { "테스트 번호 \($0)" } ?? "설정되지 않은 테스트 번호"
#else
        "112"
#endif
    }

    private static func sanitizedPhoneNumber(_ value: String) -> String? {
        let compactNumber = value.filter { character in
            character.isNumber || character == "+"
        }
        guard compactNumber.count >= 3 else { return nil }
        return compactNumber
    }
}

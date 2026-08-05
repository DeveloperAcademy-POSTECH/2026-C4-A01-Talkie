//
//  SOSEmergencyDestination.swift
//  Talkie
//

import Foundation

/// 112 문자/전화 신고 대상을 한 곳에서 결정합니다.
/// 문자 전송과 전화 연결은 모두 iOS 시스템 화면에서 사용자가 마지막으로 확인합니다.
enum SOSEmergencyDestination {
    static var phoneNumber: String {
        "112"
    }

    static var displayName: String {
        "112"
    }
}

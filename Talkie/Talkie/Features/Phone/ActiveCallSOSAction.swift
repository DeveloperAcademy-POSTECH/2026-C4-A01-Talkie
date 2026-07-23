//
//  ActiveCallSOSAction.swift
//  Talkie
//

import Foundation

/// 진행 중인 가상 통화를 종료한 뒤 실행할 안전 기능과 확인 문구입니다.
enum ActiveCallSOSAction: String, Identifiable {
    case locationShare
    case emergencySMS
    case emergencyCall

    var id: String { rawValue }

    var confirmationTitle: String {
        switch self {
        case .locationShare:
            "안전 연락망에 위치를 공유할까요?"
        case .emergencySMS:
            "112 문자 신고를 준비할까요?"
        case .emergencyCall:
            "112에 전화할까요?"
        }
    }

    var confirmationMessage: String {
        switch self {
        case .locationShare:
            "현재 가상 통화를 종료하고 위치가 포함된 메시지 작성 화면을 엽니다. 메시지는 사용자가 직접 전송합니다."
        case .emergencySMS:
            "현재 가상 통화를 종료하고 위치가 포함된 \(SOSEmergencyDestination.displayName) 문자 작성 화면을 엽니다. 문자는 사용자가 직접 전송합니다."
        case .emergencyCall:
            "현재 가상 통화를 종료하고 시스템 전화 확인 화면을 엽니다. 확인하면 \(SOSEmergencyDestination.displayName)로 연결됩니다."
        }
    }

    var confirmButtonTitle: String {
        switch self {
        case .locationShare:
            "위치 공유 준비"
        case .emergencySMS:
            "문자 작성"
        case .emergencyCall:
            "112 전화"
        }
    }

    var isEmergency: Bool {
        self != .locationShare
    }
}

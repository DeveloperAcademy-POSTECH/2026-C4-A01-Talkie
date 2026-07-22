//
//  SOSError.swift
//  Talkie
//
//  Created by DS on 7/19/26.
//

import Foundation

enum SOSError: Error {
    case locationPermissionDenied
    case locationUnavailable
    case noEmergencyContacts
    case messageUnavailable
    case cannotMakePhoneCall
    case testEmergencyNumberNotConfigured
    
    var message: String {
        switch self {
        case .locationPermissionDenied:
            return "위치 권한이 허용되지 않았습니다."
        case .locationUnavailable:
            return "현재 위치를 가져올 수 없습니다."
        case .noEmergencyContacts:
            return "등록된 안전 연락망이 없습니다."
        case .messageUnavailable:
            return "이 기기에서는 문자 메시지를 보낼 수 없습니다."
        case .cannotMakePhoneCall:
            return "이 기기에서는 전화 연결을 할 수 없습니다."
        case .testEmergencyNumberNotConfigured:
            return "Debug 빌드의 신고 테스트 번호가 설정되지 않았습니다. Xcode Scheme에 TALKIE_SOS_TEST_NUMBER를 설정해주세요."
        }
    }
}

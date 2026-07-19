//
//  SOSManager.swift
//  Talkie
//
//  Created by DS on 7/19/26.
//

import Foundation
import Observation

enum SOSError: Error {
    case locationPermissionDenied
    case locationUnavailable
    case noEmergencyContacts
    
    var message: String {
        switch self {
        case .locationPermissionDenied:
            return "위치 권한이 허용되지 않았습니다."
        case .locationUnavailable:
            return "현재 위치를 가져올 수 없습니다."
        case .noEmergencyContacts:
            return "등록된 안전 연락망이 없습니다."
        }
    }
}

@Observable
final class SOSManager {
    // 디자이너용 상태값입니다.
    // 실제 위치 조회, SwiftData 조회, 문자/전화 연결은 다음 이슈에서 연결합니다.
    var isLoading: Bool = false
    var locationError: SOSError?
    var hasEmergencyContacts: Bool = true
    
    func shareLocationToContacts() {
        guard !isLoading else {
            return
        }
        
        locationError = nil
        isLoading = true
        
        // 와이어프레임 테스트용 가짜 로딩입니다.
        // 디자이너는 이 상태를 이용해 스피너, 버튼 비활성화, 강조 테두리 등을 확인할 수 있습니다.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            isLoading = false
        }
    }
    
    func sendEmergencySMS112() {
        print("112 문자 신고 트리거")
    }
    
    func call112() {
        print("112 전화 연결 트리거")
    }
}

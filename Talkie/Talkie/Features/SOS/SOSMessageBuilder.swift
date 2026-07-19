//
//  SOSMessageBuilder.swift
//  Talkie
//
//  Created by DS on 7/19/26.
//

import CoreLocation
import Foundation

enum SOSMessageComposeMode {
    case locationShare
    case emergencySMS112
}

struct SOSMessageRequest {
    let mode: SOSMessageComposeMode
    let recipients: [String]
}

enum SOSMessageBuilder {
    static func googleMapsLink(from coordinate: CLLocationCoordinate2D) -> String {
        "https://maps.google.com/?q=\(coordinate.latitude),\(coordinate.longitude)"
    }
    
    static func messageBody(
        mode: SOSMessageComposeMode,
        mapLink: String
    ) -> String {
        switch mode {
        case .locationShare:
            return """
            [Talkie 위치 공유 알림] 현재 위험한 상황일 수 있습니다. 아래 링크에서 위치를 확인해주세요.
            현재 위치: \(mapLink)
            """
        case .emergencySMS112:
            return """
            [Talkie 긴급 신고] 구조가 필요한 상황입니다. 현재 위치 확인을 부탁드립니다.
            현재 위치: \(mapLink)
            """
        }
    }
}

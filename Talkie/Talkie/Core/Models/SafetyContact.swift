//
//  SafetyContact.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import Foundation
import SwiftData

@Model
final class SafetyContact {
    var id: UUID
    var name: String
    var phoneNumber: String
    var shouldShareLocation: Bool = true
    /// 여러 기기에서 수정됐을 때 최신 연락처를 선택하기 위한 시각입니다.
    var updatedAt: Date = Date()
    
    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String,
        shouldShareLocation: Bool = true,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.shouldShareLocation = shouldShareLocation
        self.updatedAt = updatedAt
    }
}

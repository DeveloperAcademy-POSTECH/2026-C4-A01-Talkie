//
//  EmergencyContact.swift
//  Talkie
//
//  Created by DS on 7/13/26.
//
import Foundation
import SwiftData

@Model
final class EmergencyContact {
    var id: UUID
    var name: String            // 예: "엄마", "민우", "112"
    var phoneNumber: String     // 예: "010-1234-5678"
    var relation: String        // 예: "가족", "친구", "긴급기관"
    var isPrimary: Bool         // 최우선 비상 연락처 여부
    var sortOrder: Int          // 정렬 순서
    
    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String,
        relation: String = "기타",
        isPrimary: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.relation = relation
        self.isPrimary = isPrimary
        self.sortOrder = sortOrder
    }
}

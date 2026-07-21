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
    
    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
    }
}

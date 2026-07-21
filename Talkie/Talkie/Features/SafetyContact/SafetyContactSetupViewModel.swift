//
//  SafetyContactSetupViewModel.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import Foundation
import Observation
import SwiftData

struct SafetyContactInput: Identifiable {
    let id = UUID()
    var name: String = ""
    var phoneNumber: String = ""
    
    var isComplete: Bool {
        !trimmedName.isEmpty && !trimmedPhoneNumber.isEmpty
    }
    
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var trimmedPhoneNumber: String {
        phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@Observable
final class SafetyContactSetupViewModel {
    var contactInputs: [SafetyContactInput]
    var errorMessage: String?
    
    init() {
        contactInputs = Array(repeating: SafetyContactInput(), count: 3)
    }
    
    var canStart: Bool {
        contactInputs.contains(where: \.isComplete)
    }
    
    func addContactInput() {
        contactInputs.append(SafetyContactInput())
    }
    
    func saveContacts(
        modelContext: ModelContext,
        onComplete: () -> Void
    ) {
        let contacts = contactInputs
            .filter(\.isComplete)
            .map {
                SafetyContact(
                    name: $0.trimmedName,
                    phoneNumber: $0.trimmedPhoneNumber
                )
            }
        
        guard !contacts.isEmpty else {
            errorMessage = "최소 1개의 안전 연락망을 입력해주세요."
            return
        }
        
        contacts.forEach { contact in
            modelContext.insert(contact)
        }
        
        do {
            try modelContext.save()
            onComplete()
        } catch {
            errorMessage = "안전 연락망을 저장하지 못했습니다."
            print("안전 연락망 저장 실패: \(error.localizedDescription)")
        }
    }
}

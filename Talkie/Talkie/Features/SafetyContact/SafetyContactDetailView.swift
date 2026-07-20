//
//  SafetyContactDetailView.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import SwiftUI

struct SafetyContactDetailView: View {
    let contact: SafetyContact
    
    var body: some View {
        Form {
            Section("이름") {
                Text(contact.name)
            }
            
            Section("전화번호") {
                Text(contact.phoneNumber)
            }
        }
        .navigationTitle("연락망 상세")
    }
}

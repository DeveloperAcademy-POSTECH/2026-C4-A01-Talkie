//
//  SafetyContactListView.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import SwiftUI
import SwiftData

struct SafetyContactListView: View {
    @Query(sort: \SafetyContact.name)
    private var safetyContacts: [SafetyContact]
    
    var body: some View {
        List {
            if safetyContacts.isEmpty {
                ContentUnavailableView(
                    "등록된 안전 연락망이 없습니다",
                    systemImage: "person.crop.circle.badge.plus"
                )
            } else {
                ForEach(safetyContacts) { contact in
                    NavigationLink {
                        SafetyContactDetailView(contact: contact)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(contact.name)
                            Text(contact.phoneNumber)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("안전 연락망")
    }
}

#Preview {
    NavigationStack {
        SafetyContactListView()
    }
}

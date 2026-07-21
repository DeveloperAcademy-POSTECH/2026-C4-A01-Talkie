//
//  SafetyContactDetailView.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import SwiftUI
import SwiftData

struct SafetyContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let contact: SafetyContact?
    
    @State private var name: String
    @State private var phoneNumber: String
    
    init(contact: SafetyContact?) {
        self.contact = contact
        _name = State(initialValue: contact?.name ?? "")
        _phoneNumber = State(initialValue: contact?.phoneNumber ?? "")
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("이름")
                        .foregroundStyle(.white.opacity(0.7))
                    
                    TextField("이름", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("연락처")
                        .foregroundStyle(.white.opacity(0.7))
                    
                    TextField("전화번호", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textFieldStyle(.roundedBorder)
                }
                
                Spacer()
            }
            .padding(20)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saveContact()
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("연락망 상세")
        .preferredColorScheme(.dark)
    }
    
    private func saveContact() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let contact {
            contact.name = trimmedName
            contact.phoneNumber = trimmedPhoneNumber
        } else {
            let contact = SafetyContact(
                name: trimmedName,
                phoneNumber: trimmedPhoneNumber
            )
            modelContext.insert(contact)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("안전 연락망 저장 실패: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let container = try! PreviewContainerFactory.makeSafetyContactContainer()
    let contact = SafetyContact(name: "엄마", phoneNumber: "010-1234-5678")
    
    return NavigationStack {
        SafetyContactDetailView(contact: contact)
    }
    .modelContainer(container)
}

//
//  CallerProfileSetupView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI
import SwiftData

struct CallerProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var callername: String = ""
    @State private var callerRelationship: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("가짜 전화 프로필 설정")
                        .font(.title)
                        .bold()
                    Text("불안한 순간, 나에게 전화를 걸어줄 상대의 정보를 입력해 주세요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    VStack(spacing: 16) {
                        TextField("상대 이름", text: $callername)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("관계", text: $callerRelationship)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Button {
                        saveCallerProfile()
                    } label: {
                        Text("저장하고 시작하기")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isInputValid)
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var isInputValid: Bool {
        !callername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !callerRelationship.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveCallerProfile() {
        let callerProfile = CallerProfile(
            name: callername.trimmingCharacters(in: .whitespacesAndNewlines),
            relationship: callerRelationship.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        modelContext.insert(callerProfile)
    }
}

#Preview {
    CallerProfileSetupView()
}

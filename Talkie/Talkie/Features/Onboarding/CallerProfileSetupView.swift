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
    @State private var viewModel = CallerProfileSetupViewModel()
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationStack {
            Form {
                Section {
                    TextField("상대 이름", text: $viewModel.name)
                    TextField("관계", text: $viewModel.relationship)
                } header: {
                    Text("가짜 전화 프로필")
                } footer: {
                    Text("관계에 따라 기본 통화 대사가 자동으로 설정됩니다.")
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("프로필 설정")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        viewModel.saveProfile(modelContext: modelContext)
                    }
                    .disabled(viewModel.isSaveDisabled)
                }
            }
        }
    }
}

#Preview {
    CallerProfileSetupView()
}

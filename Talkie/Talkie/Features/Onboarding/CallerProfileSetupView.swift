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
                } header: {
                    Text("통화 상대")
                } footer: {
                    Text("저장하면 기본 시나리오와 대사가 함께 생성됩니다.")
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

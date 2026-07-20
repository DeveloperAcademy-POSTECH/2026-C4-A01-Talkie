//
//  SafetyContactSetupView.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import SwiftUI
import SwiftData

struct SafetyContactSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SafetyContactSetupViewModel()
    
    let onComplete: () -> Void
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("안심 연락망을 입력해주세요.")
                    .font(.title2)
                    .bold()
                
                Text("설정에서 언제든지 변경할 수 있어요.")
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 16) {
                ForEach(viewModel.contactInputs.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("연락망 \(index + 1)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            TextField("이름", text: $viewModel.contactInputs[index].name)
                            TextField("전화번호", text: $viewModel.contactInputs[index].phoneNumber)
                                .keyboardType(.phonePad)
                        }
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
            
            Button("+ 연락망 추가하기") {
                viewModel.addContactInput()
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
            
            Spacer()
            
            Button {
                viewModel.saveContacts(
                    modelContext: modelContext,
                    onComplete: onComplete
                )
            } label: {
                Text("시작하기")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .background(viewModel.canStart ? Color.orange : Color.gray.opacity(0.3))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(!viewModel.canStart)
        }
        .padding(24)
    }
}

#Preview {
    SafetyContactSetupView { }
}

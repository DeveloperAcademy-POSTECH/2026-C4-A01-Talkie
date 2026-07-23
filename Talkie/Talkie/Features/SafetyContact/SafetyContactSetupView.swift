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
        
        DarkScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("안심 연락망을 입력해주세요.")
                        .font(Font.pretendard(.semiBold, size: 24))
                        .foregroundColor(Constants.grey100)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    Text("설정에서 언제든지 변경할 수 있어요.")
                        .font(Font.pretendard(.regular, size: 16))
                        .foregroundColor(Constants.grey300)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                
                VStack(spacing: 16) {
                    ForEach(viewModel.contactInputs.indices, id: \.self) { index in
                        contactInputRow(
                            index: index,
                            name: $viewModel.contactInputs[index].name,
                            phoneNumber: phoneNumberBinding(for: index)
                        )
                    }
                }
                .padding(.top, 40)
                
                Button {
                    viewModel.addContactInput()
                } label: {
                    Text("+ 연락망 추가하기")
                        .font(Font.pretendard(.medium, size: 16))
                        .foregroundColor(Constants.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding(.top, 16)
                }
                
                Spacer()
                
                Button {
                    viewModel.saveContacts(
                        modelContext: modelContext,
                        onComplete: onComplete
                    )
                } label: {
                    Text("시작하기")
                        .font(Font.pretendard(.medium, size: 16))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 16)
                }
                .background(viewModel.canStart ? Constants.main500 : Constants.surfaceDisable)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .disabled(!viewModel.canStart)
            }
            .padding(.horizontal, 16)
            .padding(.top, 120)
            .padding(.bottom, 32)
        }
    }
}

private extension SafetyContactSetupView {
    func phoneNumberBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                viewModel.contactInputs[index].phoneNumber
            },
            set: { newValue in
                viewModel.contactInputs[index].phoneNumber = PhoneNumberFormatter.format(newValue)
            }
        )
    }

    func contactInputRow(
        index: Int,
        name: Binding<String>,
        phoneNumber: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("연락망\(index + 1)")
                .font(Font.pretendard(.medium, size: 14))
                .foregroundColor(Constants.textSecondary)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            HStack(alignment: .center, spacing: 8) {
                contactTextField(
                    placeholder: "이름",
                    text: name
                )
                .frame(width: 100)

                contactTextField(
                    placeholder: "전화번호",
                    text: phoneNumber,
                    keyboardType: .phonePad
                )
            }
        }
    }

    func contactTextField(
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        TextField(
            "",
            text: text,
            prompt: Text(placeholder)
                .foregroundColor(Constants.grey400)
        )
        .font(Font.pretendard(.medium, size: 16))
        .foregroundColor(Constants.grey100)
        .keyboardType(keyboardType)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Constants.surfaceTextField)
        .cornerRadius(12)
    }
}

#Preview {
    SafetyContactSetupView { }
}

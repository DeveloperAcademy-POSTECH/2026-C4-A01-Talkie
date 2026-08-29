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
    @FocusState private var focusedField: ContactInputField?
    
    let onComplete: () -> Void
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        DarkScreen {
            ZStack(alignment: .bottom) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = nil
                    }

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("안전 연락망을 입력해주세요.")
                            .font(Font.pretendard(.semiBold, size: 24))
                            .foregroundColor(Constants.grey100)
                            .frame(maxWidth: .infinity, alignment: .topLeading)

                        Text("위급한 상황에 등록한 연락처로 현재 위치를 전송합니다. 설정에서 언제든 변경할 수 있어요.")
                            .font(Font.pretendard(.regular, size: 16))
                            .foregroundColor(Constants.grey300)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }

                    VStack(spacing: 16) {
                        ForEach(viewModel.contactInputs.indices, id: \.self) { index in
                            contactInputRow(
                                index: index,
                                name: nameBinding(for: index),
                                phoneNumber: phoneNumberBinding(for: index)
                            )
                        }
                    }
                    .padding(.top, 40)

                    Button {
                        focusedField = nil
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
                }
                .padding(.horizontal, 16)
                .padding(.top, 58)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                startButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

private enum ContactInputField: Hashable {
    case name(Int)
    case phoneNumber(Int)
}

private extension SafetyContactSetupView {
    var startButton: some View {
        Button {
            focusedField = nil
            viewModel.saveContacts(
                modelContext: modelContext,
                onComplete: onComplete
            )
        } label: {
            Text("시작하기")
                .font(Font.pretendard(.semiBold, size: 17))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 16)
        }
        .background(viewModel.canStart ? Constants.main500 : Constants.surfaceDisable)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .disabled(!viewModel.canStart)
    }

    func nameBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                viewModel.contactInputs[index].name
            },
            set: { newValue in
                updateContactInput(at: index) { input in
                    input.name = newValue
                }
            }
        )
    }

    func phoneNumberBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                viewModel.contactInputs[index].phoneNumber
            },
            set: { newValue in
                updateContactInput(at: index) { input in
                    input.phoneNumber = PhoneNumberFormatter.format(newValue)
                }
            }
        )
    }

    func updateContactInput(
        at index: Int,
        transform: (inout SafetyContactInput) -> Void
    ) {
        guard viewModel.contactInputs.indices.contains(index) else {
            return
        }

        var updatedInputs = viewModel.contactInputs
        transform(&updatedInputs[index])
        viewModel.contactInputs = updatedInputs
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
                    text: name,
                    focusedField: .name(index)
                )
                .frame(width: 100)

                contactTextField(
                    placeholder: "전화번호",
                    text: phoneNumber,
                    keyboardType: .phonePad,
                    focusedField: .phoneNumber(index)
                )
            }
        }
    }

    func contactTextField(
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        focusedField field: ContactInputField
    ) -> some View {
        TextField(
            "",
            text: text,
            prompt: Text(placeholder)
                .foregroundColor(Constants.grey400)
        )
        .textFieldStyle(.plain)
        .font(Font.pretendard(.medium, size: 16))
        .foregroundColor(Constants.grey100)
        .keyboardType(keyboardType)
        .focused($focusedField, equals: field)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 52)
        .background(Constants.surfaceTextField)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SafetyContactSetupView { }
}

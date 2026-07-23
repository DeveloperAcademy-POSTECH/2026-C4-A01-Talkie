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

            VStack(alignment: .leading, spacing: 0) {
                // 상단 네비게이션 바
                DepthNavigationBar {
                    dismiss()
                } trailingContent: {
                    Button {
                        saveContact()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Constants.grey800)
                            .frame(width: 44, height: 44)
                            .background(Constants.main500)
                            .clipShape(Circle())
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("연락망 저장")
                }

                // 메인 입려 폼 영역
                VStack(alignment: .leading, spacing: 28) {
                    // 이름 입력 섹션
                    VStack(alignment: .leading, spacing: 8) {
                        Text("이름")
                            .font(Font.custom("Pretendard", size: 14).weight(.medium))
                            .foregroundColor(Constants.textSecondary)

                        contactTextField(
                            placeholder: "이름을 입력해주세요",
                            text: $name
                        )
                    }

                    // 연락처 입력 섹션
                    VStack(alignment: .leading, spacing: 8) {
                        Text("연락처")
                            .font(Font.custom("Pretendard", size: 14).weight(.medium))
                            .foregroundColor(Constants.textSecondary)

                        contactTextField(
                            placeholder: "전화번호를 입력해주세요",
                            text: $phoneNumber,
                            keyboardType: .phonePad
                        )
                    }

                    Spacer()
                }
                .padding(.horizontal, 16) // 네비게이션 바 버튼과 라인을 일치시킵니다.
                .padding(.top, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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

// MARK: - Helper Views
private extension SafetyContactDetailView {
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
        .font(Font.custom("Pretendard", size: 16).weight(.medium))
        .foregroundColor(Constants.grey100)
        .keyboardType(keyboardType)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Constants.surfaceTextField)
        .cornerRadius(12)
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

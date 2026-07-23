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
    @State private var shouldShareLocation: Bool
    @State private var isShowingDeleteConfirmation = false

    init(contact: SafetyContact?) {
        self.contact = contact
        _name = State(initialValue: contact?.name ?? "")
        _phoneNumber = State(initialValue: PhoneNumberFormatter.format(contact?.phoneNumber ?? ""))
        _shouldShareLocation = State(initialValue: contact?.shouldShareLocation ?? true)
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        PhoneNumberFormatter.isValid(phoneNumber)
    }

    var body: some View {
        ZStack {
            DarkScreen {
                VStack(alignment: .leading, spacing: 0) {
                    // 상단 네비게이션 바
                    DepthNavigationBar {
                        dismiss()
                    } trailingContent: {
                        Button {
                            saveContact()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Constants.grey800)
                                .frame(width:48, height:48)
                                .background(Constants.main500)
                                .clipShape(Circle())
                        }
                        .disabled(!isFormValid)
                        .accessibilityLabel("연락망 저장")
                    }

                    // 메인 입력 폼 영역
                    VStack(alignment: .leading, spacing: 28) {
                        // 이름 입력 섹션
                        VStack(alignment: .leading, spacing: 8) {
                            Text("이름")
                                .font(Font.pretendard(.medium, size: 14))
                                .foregroundColor(Constants.textSecondary)

                            contactTextField(
                                placeholder: "이름을 입력해주세요",
                                text: $name
                            )
                        }

                        // 연락처 입력 섹션
                        VStack(alignment: .leading, spacing: 8) {
                            Text("연락처")
                                .font(Font.pretendard(.medium, size: 14))
                                .foregroundColor(Constants.textSecondary)

                            contactTextField(
                                placeholder: "전화번호를 입력해주세요",
                                text: formattedPhoneNumber,
                                keyboardType: .phonePad
                            )
                        }

                        Toggle(isOn: $shouldShareLocation) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("위치 공유 문자 보내기")
                                    .font(Font.pretendard(.medium, size: 16))
                                    .foregroundColor(Constants.grey100)

                                Text("SOS 탭에서 위치 공유를 실행하면 이 연락처로 문자가 전송됩니다.")
                                    .font(Font.pretendard(.regular, size: 13))
                                    .foregroundColor(Constants.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(1)
                            }
                        }
                        .toggleStyle(.switch)
                        .tint(Constants.main500)
                        .padding(16)
                        .background(Constants.surfaceTextField)
                        .cornerRadius(16)

                        Spacer()

                        if contact != nil {
                            deleteButton
                        }
                    }
                    .padding(.horizontal, 16) // 네비게이션 바 버튼과 라인을 일치시킵니다.
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }

            if isShowingDeleteConfirmation {
                deleteConfirmationOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func saveContact() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhoneNumber = PhoneNumberFormatter.format(phoneNumber)

        guard isFormValid else {
            return
        }

        if let contact {
            contact.name = trimmedName
            contact.phoneNumber = trimmedPhoneNumber
            contact.shouldShareLocation = shouldShareLocation
        } else {
            let contact = SafetyContact(
                name: trimmedName,
                phoneNumber: trimmedPhoneNumber,
                shouldShareLocation: shouldShareLocation
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

    private func requestDeleteContact() {
        isShowingDeleteConfirmation = true
    }

    private func cancelDeleteContact() {
        isShowingDeleteConfirmation = false
    }

    private func confirmDeleteContact() {
        guard let contact else {
            isShowingDeleteConfirmation = false
            return
        }

        modelContext.delete(contact)

        do {
            try modelContext.save()
            isShowingDeleteConfirmation = false
            dismiss()
        } catch {
            modelContext.rollback()
            isShowingDeleteConfirmation = false
            print("안전 연락망 삭제 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - Helper Views
private extension SafetyContactDetailView {
    var deleteButton: some View {
        Button(action: requestDeleteContact) {
            Text("삭제하기")
                .font(Font.pretendard(.semiBold, size: 16))
                .foregroundColor(Constants.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 16)
                .background(Constants.primaryNormal)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("안전 연락망 삭제")
    }

    var deleteConfirmationOverlay: some View {
        DeleteConfirmationOverlay(
            title: "연락망을 삭제하시겠습니까?",
            onCancel: cancelDeleteContact,
            onConfirm: confirmDeleteContact
        )
    }

    var formattedPhoneNumber: Binding<String> {
        Binding(
            get: {
                phoneNumber
            },
            set: { newValue in
                phoneNumber = PhoneNumberFormatter.format(newValue)
            }
        )
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
    let container = try! PreviewContainerFactory.makeSafetyContactContainer()
    let contact = SafetyContact(name: "엄마", phoneNumber: "010-1234-5678")

    return NavigationStack {
        SafetyContactDetailView(contact: contact)
    }
    .modelContainer(container)
}

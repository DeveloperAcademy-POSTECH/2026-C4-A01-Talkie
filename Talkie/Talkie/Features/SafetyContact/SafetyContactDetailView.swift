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
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Constants.grey800)
                                .frame(width:40, height:40)
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
                                text: formattedPhoneNumber,
                                keyboardType: .phonePad
                            )
                        }

                        Toggle(isOn: $shouldShareLocation) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("위치 공유 문자 보내기")
                                    .font(Font.custom("Pretendard", size: 16).weight(.medium))
                                    .foregroundColor(Constants.grey100)

                                Text("SOS 탭에서 위치 공유를 실행하면 이 연락처로 문자가 전송됩니다.")
                                    .font(Font.custom("Pretendard", size: 13))
                                    .foregroundColor(Constants.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
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
                .font(Font.custom("Pretendard", size: 16).weight(.semibold))
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
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .onTapGesture {
                    cancelDeleteContact()
                }

            VStack(alignment: .center, spacing: 20) {
                VStack(alignment: .center, spacing: 6) {
                    Text("연락망을 삭제하시겠습니까?")
                        .font(Font.custom("Pretendard", size: 18).weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Constants.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .top)

                    Text("다시 복구할 수 없습니다.")
                        .font(Font.custom("Pretendard", size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Constants.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .top)
                }

                Image("Group 18")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 83)
                    .padding(.top, 20)
                    .padding(.bottom, 32)

                HStack(alignment: .center, spacing: 10) {
                    Button(action: cancelDeleteContact) {
                        Text("취소")
                            .font(Font.custom("Pretendard", size: 16).weight(.semibold))
                            .foregroundColor(Constants.textInverse)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 44)
                            .padding(.vertical, 12)
                            .background(Constants.surfaceDisable)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button(action: confirmDeleteContact) {
                        Text("삭제하기")
                            .font(Font.custom("Pretendard", size: 16).weight(.semibold))
                            .foregroundColor(Constants.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 44)
                            .padding(.vertical, 12)
                            .background(Constants.primaryNormal)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)
            .padding(.bottom, 16)
            .frame(width: 336, alignment: .top)
            .background(Constants.bgRegular)
            .cornerRadius(24)
        }
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

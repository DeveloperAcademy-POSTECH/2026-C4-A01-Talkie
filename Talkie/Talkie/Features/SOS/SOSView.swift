//
//  SOSView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI
import SwiftData
import UIKit

struct SOSView: View {
    @State private var sosManager = SOSManager()
    @State private var selectedAction: SOSAction?

    @Query(sort: \SafetyContact.name)
    private var safetyContacts: [SafetyContact]

    var body: some View {
        DarkScreen {
            VStack(alignment: .leading, spacing: 0) {
                MainTabHeader(title: "SOS")
                    .padding(.top, 32)

                VStack(alignment: .leading, spacing: 28) {
                    dangerTitle

                    Text("아래 버튼을 눌러 현재 위치 공유 또는 신고를 선택할 수 있어요.")
                        .font(.pretendard(.regular, size: 14))
                        .foregroundColor(Constants.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 16)

                VStack(spacing: 20) {
                    Button {
                        selectedAction = .shareLocation
                        sosManager.shareLocationToContacts(
                            safetyContacts: safetyContacts
                        )
                    } label: {
                        actionRow(
                            title: "안전 연락망에 위치 공유",
                            systemImage: "person.crop.circle.fill",
                            isHighlighted: selectedAction == .shareLocation
                        )
                    }
                    .disabled(sosManager.isLoading)
                    .buttonStyle(.plain)

                    Button {
                        selectedAction = .sms112
                        sosManager.sendEmergencySMS112()
                    } label: {
                        actionRow(
                            title: "112 문자 신고",
                            systemImage: "envelope.fill",
                            isHighlighted: selectedAction == .sms112
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        selectedAction = .call112
                        sosManager.callEmergencyServices()
                    } label: {
                        actionRow(
                            title: "112 전화 신고",
                            systemImage: "phone.fill",
                            isHighlighted: selectedAction == .call112
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                Spacer()

                warningText
                    .padding(.horizontal, 16)
                    .padding(.bottom, 104)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $sosManager.shouldShowMessageCompose) {
            MessageComposerView(
                mode: sosManager.messageComposeMode,
                recipients: sosManager.messageRecipients,
                body: sosManager.messageBody
            ) {
                sosManager.shouldShowMessageCompose = false
            }
        }
        .alert(
            "SOS 오류",
            isPresented: Binding(
                get: { sosManager.currentError != nil },
                set: { isPresented in
                    if !isPresented {
                        sosManager.currentError = nil
                    }
                }
            )
        ) {
            if sosManager.currentError == .locationPermissionDenied {
                Button("설정 열기") {
                    openAppSettings()
                    sosManager.currentError = nil
                }
            }

            Button("확인", role: .cancel) { }
        } message: {
            Text(sosManager.currentError?.message ?? "")
        }
    }
}

private enum SOSAction {
    case shareLocation
    case sms112
    case call112
}

private extension SOSView {
    var dangerTitle: some View {
        HStack(spacing: 0) {
            Text("지금 ")
                .foregroundColor(Constants.textPrimary)

            Text("위험하신가요?")
                .foregroundColor(Constants.primaryNormal)
        }
        .font(.pretendard(.semiBold, size: 28))
    }

    func actionRow(
        title: String,
        systemImage: String,
        isHighlighted: Bool
    ) -> some View {
        HStack(alignment: .center) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(isHighlighted ? Constants.primaryNormal : Constants.textTertiary)
                .frame(width: 36, height: 36)

            Text(title)
                .font(.pretendard(.semiBold, size: 20))
                .foregroundColor(isHighlighted ? Constants.primaryNormal : Constants.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isHighlighted ? Constants.primaryNormal : Constants.textTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHighlighted ? Constants.bgRegular : Constants.grey700)
        .cornerRadius(24)
        .overlay {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 24)
                    .inset(by: 0.5)
                    .stroke(Constants.primaryNormal, lineWidth: 1)
            }
        }
    }

    var warningText: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(size: 16))
                .foregroundColor(Constants.textTertiary)
                .padding(.top, 2)

            Text("허위 신고 시 형법 제137조(위계에 의한 공무집행방해) 및 112신고의 운영 및 처리에 관한 법률 제18조(500만원 이하 과태료)에 따라 처벌 받을 수 있습니다.")
                .font(.pretendard(.regular, size: 12))
                .foregroundColor(Constants.textTertiary)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .lineSpacing(4)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(settingsURL)
    }
}

#Preview {
    SOSView()
        .modelContainer(for: SafetyContact.self, inMemory: true)
}

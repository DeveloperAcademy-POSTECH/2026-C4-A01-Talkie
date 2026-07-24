//
//  SafetyContactListView.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import SwiftUI
import SwiftData

struct SafetyContactListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingAddContact = false

    @Query(sort: \SafetyContact.name)
    private var safetyContacts: [SafetyContact]

    var body: some View {
        DarkScreen {
            VStack(alignment: .leading, spacing: 0) {
                DepthNavigationBar {
                    dismiss()
                } trailingContent: {
                    addContactButton
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("안전 연락망")
                        .font(Font.pretendard(.bold, size: 22))
                        .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("가상 전화를 하는 중에 위치공유를 선택하면")
                        Text("등록된 연락처로 현재 위치를 문자로 전송할 수 있어요.")
                    }
                        .font(Font.pretendard(.regular, size: 15))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineSpacing(6)
                        .padding(.top, 8)

                    Group {
                        if safetyContacts.isEmpty {
                            ContentUnavailableView(
                                "등록된 안전 연락망이 없습니다",
                                systemImage: "person.crop.circle.badge.plus"
                            )
                            .foregroundStyle(.white)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(safetyContacts) { contact in
                                    NavigationLink {
                                        SafetyContactDetailView(contact: contact)
                                    } label: {
                                        HStack {
                                            Text(contact.name)
                                                .font(Font.pretendard(.medium, size: 16))
                                                .foregroundStyle(.white)

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.white.opacity(0.4))
                                                .accessibilityHidden(true)
                                        }
                                        .padding(18)
                                        .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                                        .background(Constants.surfaceTextField)
                                        .clipShape(RoundedRectangle(cornerRadius: 28))
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("\(contact.name) 연락망 상세 보기")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 32)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
            }
        }
        .edgeSwipeBack {
            dismiss()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isShowingAddContact) {
            SafetyContactDetailView(contact: nil)
        }
    }

    private var addContactButton: some View {
        Button {
            isShowingAddContact = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(Constants.grey800)
                .frame(width: 48, height: 48)
                .background(Constants.main500)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("안전 연락망 추가")
    }
}

#Preview {
    let container = try! PreviewContainerFactory.makeSafetyContactContainer()

    NavigationStack {
        SafetyContactListView()
    }
    .modelContainer(container)
}

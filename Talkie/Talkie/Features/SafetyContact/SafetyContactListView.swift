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

                VStack(alignment: .leading, spacing: 20) {
                    Text("안전 연락망")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.white)

                    Text("가상 전화를 하는 중에 위치공유를 선택하면 등록된 연락처로 현재 위치를 문자로 전송할 수 있어요.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

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
                                            .foregroundStyle(.white)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                    .padding()
                                    .background(Constants.grey700)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
            }
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
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Constants.grey800)
                .frame(width: 40, height: 40)
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

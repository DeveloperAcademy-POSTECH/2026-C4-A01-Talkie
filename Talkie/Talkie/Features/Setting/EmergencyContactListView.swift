//
//  EmergencyContactListView.swift
//  Talkie
//

import SwiftData
import SwiftUI

/// 마이페이지에서 현재 저장된 안전 연락망을 확인하는 화면입니다.
/// 연락처 편집 흐름은 별도 기능에서 확장하고, 이 이슈에서는 저장된 연락처를 읽어 표시합니다.
struct EmergencyContactListView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \EmergencyContact.sortOrder)
    private var contacts: [EmergencyContact]

    var body: some View {
        ZStack {
            Constants.grey800
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                MyPageHeader(title: "안전 연락망", onBack: dismiss.callAsFunction)

                if contacts.isEmpty {
                    ContentUnavailableView(
                        "등록된 연락처가 없습니다",
                        systemImage: "person.2",
                        description: Text("안전 연락망을 등록하면 위치 공유에 사용할 수 있습니다.")
                    )
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(contacts) { contact in
                                HStack(spacing: 14) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.08), in: Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(contact.name)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text(contact.phoneNumber)
                                            .font(.system(size: 15))
                                            .foregroundStyle(.white.opacity(0.48))
                                    }

                                    Spacer()

                                    if contact.isPrimary {
                                        Text("대표")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(Constants.main500)
                                    }
                                }
                                .padding(.horizontal, 18)
                                .frame(minHeight: 76)
                                .background(Constants.grey700, in: RoundedRectangle(cornerRadius: 18))
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    NavigationStack {
        EmergencyContactListView()
    }
    .modelContainer(for: EmergencyContact.self, inMemory: true)
}

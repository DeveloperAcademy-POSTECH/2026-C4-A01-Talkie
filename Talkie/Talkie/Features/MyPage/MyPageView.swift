//
//  MyPageView.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import SwiftData
import SwiftUI

struct MyPageView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \CallSession.startedAt, order: .reverse)
    private var callSessions: [CallSession]

    @AppStorage(TalkiePreferenceKey.automaticCallRecordingEnabled)
    private var isAutomaticRecordingEnabled = false

    @AppStorage(TalkiePreferenceKey.iCloudSyncEnabled)
    private var isICloudSyncEnabled = false

    private var recordedCallCount: Int {
        callSessions.lazy.filter { $0.recording != nil }.count
    }

    var body: some View {
        ZStack {
            Constants.grey800
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    MyPageHeader(title: "마이페이지", onBack: dismiss.callAsFunction)

                    MyPageMenuSection(title: "안전 연락망") {
                        NavigationLink {
                            SafetyContactListView()
                        } label: {
                            MyPageNavigationRow(title: "안전 연락망 모두 보기")
                        }
                    }

                    MyPageMenuSection(title: "이전 통화내역 보기") {
                        NavigationLink {
                            CallHistoryView()
                        } label: {
                            MyPageNavigationRow(
                                title: "모든 통화내역 보기",
                                trailingText: "\(recordedCallCount)"
                            )
                        }
                    }

                    MyPageMenuSection(title: "자동 녹음") {
                        MyPageToggleRow(
                            title: "가상 통화 시 자동 녹음",
                            isOn: $isAutomaticRecordingEnabled
                        )
                    }

                    MyPageMenuSection(title: "iCloud 동기화") {
                        MyPageToggleRow(
                            title: "iCloud 동기화",
                            isOn: $isICloudSyncEnabled
                        )
                        .accessibilityHint("현재는 동기화 설정 인터페이스만 제공됩니다.")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct MyPageHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("뒤로")

                Spacer()
            }
        }
        .padding(.top, 10)
    }
}

private struct MyPageMenuSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Constants.grey300.opacity(0.72))

            content
        }
    }
}

private struct MyPageNavigationRow: View {
    let title: String
    var trailingText: String?

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.system(size: 17, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.68))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.38))
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 64)
        .background(Constants.grey700, in: RoundedRectangle(cornerRadius: 18))
        .contentShape(Rectangle())
    }
}

private struct MyPageToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.white)
            .tint(Color(red: 0.20, green: 0.78, blue: 0.35))
            .padding(.horizontal, 20)
            .frame(minHeight: 64)
            .background(Constants.grey700, in: RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
    .modelContainer(
        for: [
            CallSession.self,
            CallRecording.self,
            SafetyContact.self
        ],
        inMemory: true
    )
}

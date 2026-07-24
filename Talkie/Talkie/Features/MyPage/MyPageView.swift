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
    @Environment(CloudSyncCoordinator.self) private var cloudSyncCoordinator

    @Query(sort: \CallSession.startedAt, order: .reverse)
    private var callSessions: [CallSession]

    @Query(sort: \SafetyContact.name)
    private var safetyContacts: [SafetyContact]

    @AppStorage(TalkiePreferenceKey.automaticCallRecordingEnabled)
    private var isAutomaticRecordingEnabled = false

    @AppStorage(TalkiePreferenceKey.didAcknowledgeICloudRecordingSync)
    private var didAcknowledgeICloudRecordingSync = false

    @State private var shouldConfirmICloudRecordingSync = false

    private var recordedCallCount: Int {
        callSessions.lazy.filter { $0.recording != nil }.count
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                DepthNavigationBar(title: "마이페이지") {
                    dismiss()
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 36) {
                        MyPageMenuSection(title: "안전 연락망") {
                            NavigationLink {
                                SafetyContactListView()
                            } label: {
                                MyPageNavigationRow(
                                    title: "안전 연락망 모두 보기",
                                    trailingText: "\(safetyContacts.count)"
                                )
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
                            VStack(alignment: .leading, spacing: 10) {
                                MyPageToggleRow(
                                    title: "iCloud 동기화",
                                    isOn: Binding(
                                        get: { cloudSyncCoordinator.isEnabled },
                                        set: handleICloudToggle
                                    )
                                )
                                .accessibilityHint("시나리오, 대사 녹음, 가상 통화 녹음 및 안전 연락망을 개인 iCloud와 동기화합니다.")

                                Text(cloudSyncCoordinator.status.message)
                                    .font(Font.pretendard(.regular, size: 13))
                                    .foregroundStyle(syncStatusColor)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 36)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .edgeSwipeBack {
            dismiss()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if cloudSyncCoordinator.isEnabled && !didAcknowledgeICloudRecordingSync {
                shouldConfirmICloudRecordingSync = true
            }
        }
        .alert("가상 통화 녹음도 동기화할까요?", isPresented: $shouldConfirmICloudRecordingSync) {
            Button("취소", role: .cancel) { }
            Button("동기화 켜기") {
                didAcknowledgeICloudRecordingSync = true
                if cloudSyncCoordinator.isEnabled {
                    cloudSyncCoordinator.syncAllLocalData()
                } else {
                    cloudSyncCoordinator.setEnabled(true)
                }
            }
        } message: {
            Text("자동 녹음에는 사용자의 목소리와 주변 소리가 포함될 수 있으며, 녹음 파일은 사용자의 개인 iCloud에 저장됩니다.")
        }
    }

    private func handleICloudToggle(_ enabled: Bool) {
        guard enabled else {
            cloudSyncCoordinator.setEnabled(false)
            return
        }

        if didAcknowledgeICloudRecordingSync {
            cloudSyncCoordinator.setEnabled(true)
        } else {
            shouldConfirmICloudRecordingSync = true
        }
    }

    private var syncStatusColor: Color {
        switch cloudSyncCoordinator.status {
        case .failed, .unavailable:
            Constants.primaryNormal
        default:
            Constants.textSecondary
        }
    }
}

private struct MyPageMenuSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Font.pretendard(.semiBold, size: 17))
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
                .font(Font.pretendard(.medium, size: 18))
                .foregroundStyle(.white)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(Font.pretendard(.medium, size: 17).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.68))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.38))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 64)
        .background(Constants.grey700, in: RoundedRectangle(cornerRadius: 28))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct MyPageToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .font(Font.pretendard(.medium, size: 18))
            .foregroundStyle(.white)
            .tint(Color(red: 0.20, green: 0.78, blue: 0.35))
            .padding(.horizontal, 20)
            .frame(minHeight: 64)
            .background(Constants.grey700, in: RoundedRectangle(cornerRadius: 28))
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Scenario.self,
        ScriptLine.self,
        AudioClipMetadata.self,
        SafetyContact.self,
        CallSession.self,
        CallRecording.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    NavigationStack {
        MyPageView()
    }
    .modelContainer(container)
    .environment(CloudSyncCoordinator(modelContainer: container))
}

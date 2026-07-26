//
//  CallHistoryView.swift
//  Talkie
//

import SwiftData
import SwiftUI

struct CallHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CallSession.startedAt, order: .reverse)
    private var callSessions: [CallSession]

    @State private var player = CallRecordingPlayer()
    @State private var isSelecting = false
    @State private var selectedSessionIDs: Set<UUID> = []
    @State private var shouldConfirmDeletion = false
    @State private var deletionError: String?

    private var recordedSessions: [CallSession] {
        callSessions.filter { $0.recording != nil }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            VStack(alignment: .leading, spacing: 24) {
                CallHistoryHeader(
                    isSelecting: isSelecting,
                    onBack: dismiss.callAsFunction,
                    onToggleSelection: toggleSelectionMode
                )

                Text("통화 내역")
                    .font(Font.pretendard(.semiBold, size: 20))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 27, maxHeight: 27, alignment: .topLeading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                historyContent
            }

            if isSelecting {
                deleteButton
                    .padding(.trailing, 28)
                    .padding(.bottom, 28)
            }

            if shouldConfirmDeletion {
                DeleteConfirmationOverlay(
                    title: "녹음본을 삭제하시겠습니까?",
                    onCancel: {
                        shouldConfirmDeletion = false
                    },
                    onConfirm: deleteSelectedSessions
                )
            }
        }
        .preferredColorScheme(.dark)
        .edgeSwipeBack {
            dismiss()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onDisappear(perform: player.stop)
        .alert(
            "작업 실패",
            isPresented: Binding(
                get: { player.errorMessage != nil || deletionError != nil },
                set: { isPresented in
                    if !isPresented {
                        player.clearError()
                        deletionError = nil
                    }
                }
            )
        ) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(player.errorMessage ?? deletionError ?? "")
        }
    }

    @ViewBuilder
    private var historyContent: some View {
        if recordedSessions.isEmpty {
            ContentUnavailableView(
                "녹음된 통화가 없습니다",
                systemImage: "waveform",
                description: Text("자동 녹음을 켠 뒤 가상 통화를 완료하면 여기에 표시됩니다.")
            )
            .foregroundStyle(.white.opacity(0.72))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(recordedSessions) { session in
                        CallHistoryRow(
                            session: session,
                            isSelecting: isSelecting,
                            isSelected: selectedSessionIDs.contains(session.id),
                            isPlaying: player.activeRecordingID == session.recording?.id
                                && player.isPlaying,
                            onTap: { handleRowTap(session) },
                            onPlay: { play(session) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, isSelecting ? 104 : 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var deleteButton: some View {
        Button {
            shouldConfirmDeletion = true
        } label: {
            Image(systemName: "trash.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.white.opacity(0.08), in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                }
        }
        .disabled(selectedSessionIDs.isEmpty)
        .opacity(selectedSessionIDs.isEmpty ? 0.35 : 1)
        .accessibilityLabel("선택한 통화내역 삭제")
        .accessibilityValue("\(selectedSessionIDs.count)개 선택됨")
    }

    private func toggleSelectionMode() {
        player.stop()
        isSelecting.toggle()
        if !isSelecting {
            selectedSessionIDs.removeAll()
        }
    }

    private func handleRowTap(_ session: CallSession) {
        guard isSelecting else { return }
        if selectedSessionIDs.contains(session.id) {
            selectedSessionIDs.remove(session.id)
        } else {
            selectedSessionIDs.insert(session.id)
        }
    }

    private func play(_ session: CallSession) {
        guard !isSelecting, let recording = session.recording else { return }
        player.toggle(recording)
    }

    private func deleteSelectedSessions() {
        player.stop()
        let targets = recordedSessions.filter { selectedSessionIDs.contains($0.id) }
        let sessionIDs = targets.map(\.id)
        let fileNames = targets.compactMap { $0.recording?.fileName }

        do {
            for session in targets {
                modelContext.delete(session)
            }
            try modelContext.save()
            sessionIDs.forEach(CloudSyncChangeTracker.deletedCallSession)

            // 메타데이터 삭제를 먼저 확정해 앱 목록과 저장소가 반쯤 삭제되는 상태를 피합니다.
            // 이후 파일 정리가 실패해도 다음 정리 작업에서 제거할 수 있는 고아 파일만 남습니다.
            let fileStore = CallRecordingFileStore()
            var failedFileCount = 0
            for fileName in fileNames {
                do {
                    try fileStore.delete(fileName: fileName)
                } catch {
                    failedFileCount += 1
                }
            }

            selectedSessionIDs.removeAll()
            isSelecting = false
            shouldConfirmDeletion = false
            if failedFileCount > 0 {
                deletionError = "통화내역은 삭제했지만 일부 녹음 파일을 정리하지 못했습니다."
            }
        } catch {
            modelContext.rollback()
            shouldConfirmDeletion = false
            deletionError = "선택한 통화내역을 모두 삭제하지 못했습니다."
        }
    }
}

private struct CallHistoryHeader: View {
    let isSelecting: Bool
    let onBack: () -> Void
    let onToggleSelection: () -> Void

    var body: some View {
        DepthNavigationBar {
            onBack()
        } trailingContent: {
            Button(action: onToggleSelection) {
                Text(isSelecting ? "취소" : "선택")
                    .font(Font.pretendard(.semiBold, size: 16))
                    .foregroundStyle(.white)
                    .frame(width: 35, height: 28)
            }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
        }
    }
}


private struct CallHistoryRow: View {
    let session: CallSession
    let isSelecting: Bool
    let isSelected: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if isSelecting {
                selectionIndicator
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("\(Self.dateFormatter.string(from: session.startedAt)) 녹음")
                    .font(Font.pretendard(.medium, size: 18))
                    .foregroundStyle(.white)

                Text(Self.durationText(session.recording?.duration ?? 0))
                    .font(Font.pretendard(.regular, size: 16).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.38))
            }

            Spacer()

            if !isSelecting {
                Button(action: onPlay) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel(isPlaying ? "녹음 일시정지" : "녹음 재생")
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 92)
        .background(Constants.grey700, in: RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .contain)
        .accessibilityValue(isSelecting ? (isSelected ? "선택됨" : "선택되지 않음") : "")
    }

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Constants.main500 : Constants.grey800)
                .frame(width: 22, height: 22)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Constants.grey800)
            }
        }
        .accessibilityHidden(true)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy. MM. dd"
        return formatter
    }()

    private static func durationText(_ duration: TimeInterval) -> String {
        let seconds = max(0, Int(duration.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview {
    NavigationStack {
        CallHistoryView()
    }
    .modelContainer(for: [CallSession.self, CallRecording.self], inMemory: true)
}

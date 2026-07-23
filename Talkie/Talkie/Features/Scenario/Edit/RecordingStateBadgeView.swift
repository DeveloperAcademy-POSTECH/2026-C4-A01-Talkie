//
//  RecordingStateBadgeView.swift
//  Talkie
//
//  Created by DS on 7/18/26.
//

import SwiftUI

struct RecordingStateBadgeView: View {
    let isRecording: Bool
    let isRecorded: Bool
    
    var body: some View {
        if isRecording {
            HStack(spacing: 3) {
                Text("녹음 중")
                    .font(Font.pretendard(.bold, size: 12))

                RecordingWaveView()
            }
            .foregroundColor(Constants.primaryNormal)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Constants.primaryNormal.opacity(0.16))
            .cornerRadius(12)
        } else if isRecorded {
            HStack(spacing: 4) {
                Text("녹음 완료")
                    .font(Font.pretendard(.semiBold, size: 12))
                
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(Constants.textInverse)
            .padding(.leading, 10)
            .padding(.trailing, 6)
            .padding(.vertical, 3)
            .background(Constants.surfaceRecordingCompleted)
            .cornerRadius(12)
        } else {
            Text("녹음 준비")
                .font(Font.pretendard(.medium, size: 12))
                .foregroundColor(Constants.textSecondary)
                .lineLimit(1)
                .frame(height: 18)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Constants.surfaceRecordingNotYet)
                .cornerRadius(12)
        }
    }
}

private struct RecordingWaveView: View {
    @State private var isAnimating = false

    private let barHeights: [CGFloat] = [5, 9, 6]

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(barHeights.indices, id: \.self) { index in
                Capsule()
                    .fill(Constants.primaryNormal)
                    .frame(width: 2, height: isAnimating ? barHeights[index] : 4)
                    .animation(
                        .easeInOut(duration: 0.42)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.12),
                        value: isAnimating
                    )
            }
        }
        .frame(height: 10)
        .onAppear {
            isAnimating = true
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        RecordingStateBadgeView(isRecording: false, isRecorded: false)
        RecordingStateBadgeView(isRecording: true, isRecorded: false)
        RecordingStateBadgeView(isRecording: false, isRecorded: true)
    }
    .padding()
}

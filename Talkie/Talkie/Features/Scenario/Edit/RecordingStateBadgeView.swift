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
            Text("녹음 중")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Constants.primaryNormal)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Constants.primaryNormal.opacity(0.16))
                .cornerRadius(12)
        } else if isRecorded {
            HStack(spacing: 4) {
                Text("녹음 완료")
                    .font(Font.custom("Pretendard", size: 12).weight(.semibold))
                
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(Constants.textInverse)
            .padding(.leading, 8)
            .padding(.trailing, 2)
            .padding(.vertical, 2)
            .background(Constants.surfaceRecordingCompleted)
            .cornerRadius(12)
        } else {
            Text("녹음 전")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Constants.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Constants.surfaceRecordingNotYet)
                .cornerRadius(12)
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
    .background(Constants.grey800)
}

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
                .foregroundColor(Constants.main500)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Constants.main500.opacity(0.16))
                .cornerRadius(10)
        } else if isRecorded {
            HStack(spacing: 4) {
                Text("녹음 완료")
                    .font(.system(size: 12, weight: .medium))
                
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(Constants.grey800)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.84))
            .cornerRadius(10)
        } else {
            Text("녹음 전")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Constants.grey300)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
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

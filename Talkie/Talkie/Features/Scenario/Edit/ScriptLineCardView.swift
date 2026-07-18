//
//  ScriptLineCardView.swift
//  Talkie
//
//  Created by DS on 7/18/26.
//

import SwiftUI

struct ScriptLineCardView: View {
    let scriptLine: ScriptLine
    let isRecording: Bool
    let onPlay: () -> Void
    let onRecordToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RecordingStateBadgeView(
                isRecording: isRecording,
                isRecorded: scriptLine.isRecorded
            )
            
            Text(scriptLine.text)
                .font(.custom("Pretendard", size: 16))
                .foregroundColor(textColor)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Spacer()
                
                HStack(spacing: 12) {
                    if scriptLine.isRecorded && !isRecording {
                        playButton
                    }
                    
                    recordButton
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .shadow(
            color: isRecording ? Constants.main500.opacity(0.18) : .clear,
            radius: 18,
            x: 0,
            y: 8
        )
    }
    
    private var textColor: Color {
        if isRecording {
            return .white
        }
        
        return .white.opacity(scriptLine.isRecorded ? 1 : 0.72)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(isRecording ? Constants.main500.opacity(0.22) : Constants.grey700)
            .overlay {
                if isRecording {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Constants.main500.opacity(0.9), lineWidth: 1)
                }
            }
    }
    
    private var playButton: some View {
        Button(action: onPlay) {
            Image(systemName: "play.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
        .accessibilityLabel("녹음 재생")
    }
    
    private var recordButton: some View {
        Button(action: onRecordToggle) {
            Image(systemName: isRecording ? "square.fill" : "mic.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Constants.main500)
                .clipShape(Circle())
        }
        .accessibilityLabel(isRecording ? "녹음 정지" : "녹음 시작")
    }
}

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
    let isEditing: Bool
    let onDrag: () -> NSItemProvider
    let onPlay: () -> Void
    let onRecordToggle: () -> Void
    let onTextChange: (String) -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.36))
                    .onDrag(onDrag)
                    .accessibilityLabel("순서 변경")
            }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    RecordingStateBadgeView(
                        isRecording: isRecording,
                        isRecorded: scriptLine.isRecorded
                    )
                    
                    Spacer()
                    
                    if isEditing {
                        Button(action: onDelete) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.44))
                        }
                        .accessibilityLabel("대사 삭제")
                    }
                }
                
                if isEditing {
                    TextField(
                        "대사를 입력하세요.",
                        text: Binding(
                            get: { scriptLine.text },
                            set: { onTextChange($0) }
                        ),
                        axis: .vertical
                    )
                    .font(.custom("Pretendard", size: 16))
                    .foregroundColor(textColor)
                    .lineLimit(1...4)
                } else {
                    Text(scriptLine.text)
                        .font(.custom("Pretendard", size: 16))
                        .foregroundColor(textColor)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if !isEditing {
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

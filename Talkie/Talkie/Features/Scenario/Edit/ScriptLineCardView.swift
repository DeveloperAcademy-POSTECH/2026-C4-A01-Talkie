//
//  ScriptLineCardView.swift
//  Talkie
//
//  Created by DS on 7/18/26.
//

import SwiftUI
import SwiftData

struct ScriptLineCardView: View {
    let scriptLine: ScriptLine
    let isRecording: Bool
    let isPlaying: Bool
    let isEditing: Bool
    let isReadOnly: Bool
    let focusedScriptLineID: FocusState<PersistentIdentifier?>.Binding
    let onPlay: () -> Void
    let onRecordToggle: () -> Void
    let onTextChange: (String) -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    RecordingStateBadgeView(
                        isRecording: isRecording,
                        isRecorded: scriptLine.isRecorded
                    )
                    
                    Spacer()
                }
                
                if shouldShowTextField {
                    TextField(
                        "",
                        text: scriptTextBinding,
                        prompt: placeholderText,
                        axis: .vertical
                    )
                    .font(Font.pretendard(.regular, size: 16))
                    .foregroundColor(Constants.textPrimary)
                    .lineLimit(1...4)
                    .focused(focusedScriptLineID, equals: scriptLine.persistentModelID)
                    .frame(maxWidth: .infinity, minHeight: 24, alignment: .topLeading)
                } else {
                    if scriptLine.text.isEmpty {
                        placeholderText
                            .frame(maxWidth: .infinity, minHeight: 24, alignment: .topLeading)
                    } else {
                        Text(scriptLine.text)
                            .font(Font.pretendard(.regular, size: 16))
                            .foregroundColor(textColor)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, minHeight: 24, maxHeight: 24, alignment: .topLeading)
                    }
                }
            }
            .padding(.trailing, showsTrailingControls ? 52 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsTrailingControls {
                HStack(spacing: 12) {
                    if scriptLine.isRecorded && !isRecording {
                        playButton
                    }

                    recordButton
                }
                .zIndex(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(cardBackground)
        .shadow(
            color: isRecording ? Constants.primaryNormal.opacity(0.18) : .clear,
            radius: 18,
            x: 0,
            y: 8
        )
    }

    private var showsTrailingControls: Bool {
        !isEditing && !isReadOnly
    }

    private var shouldShowTextField: Bool {
        !isReadOnly
    }
    
    private var textColor: Color {
        if isRecording {
            return Constants.textPrimary
        }
        
        return scriptLine.isRecorded ? Constants.textPrimary : Constants.textSecondary
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Constants.grey700)
            .overlay(alignment: .bottom) {
                if isRecording {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Constants.main500A0, location: 0),
                            Gradient.Stop(color: Constants.main500A32, location: 1),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 1)
                    )
                    .frame(height: 50)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                if isRecording {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Constants.primaryNormal.opacity(0.9), lineWidth: 1)
                }
            }
    }

    private var scriptTextBinding: Binding<String> {
        Binding(
            get: { scriptLine.text },
            set: { onTextChange($0) }
        )
    }

    private var placeholderText: Text {
        Text("대화 내용을 입력하고 녹음해보세요.")
            .font(Font.pretendard(.regular, size: 16))
            .foregroundColor(Constants.textTertiary)
    }
    
    private var playButton: some View {
        Button(action: onPlay) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isPlaying ? Constants.primaryNormal : .white)
                .frame(width: 36, height: 36)
                .background(Constants.surfaceButton)
                .clipShape(RoundedRectangle(cornerRadius: 70))
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .zIndex(2)
        .accessibilityLabel("녹음 재생")
        .accessibilityValue(isPlaying ? "재생 중" : "정지됨")
    }
    
    private var recordButton: some View {
        Button(action: onRecordToggle) {
            Group {
                if isRecording {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Constants.grey800)
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Constants.primaryNormal)
                }
            }
                .frame(width: 28, height: 28)
                .background(isRecording ? Constants.primaryNormal : Constants.surfaceButton)
                .clipShape(RoundedRectangle(cornerRadius: 70))
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(isRecording ? "녹음 정지" : "녹음 시작")
    }
}

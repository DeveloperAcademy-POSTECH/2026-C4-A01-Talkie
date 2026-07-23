//
//  DeleteConfirmationOverlay.swift
//  Talkie
//
//  Created by DS on 7/24/26.
//

import SwiftUI

struct DeleteConfirmationOverlay: View {
    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    init(
        title: String,
        message: String = "다시 복구할 수 없습니다.",
        cancelTitle: String = "취소",
        confirmTitle: String = "삭제하기",
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.cancelTitle = cancelTitle
        self.confirmTitle = confirmTitle
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(alignment: .center, spacing: 20) {
                VStack(alignment: .center, spacing: 6) {
                    Text(title)
                        .font(Font.pretendard(.semiBold, size: 18))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Constants.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .top)

                    Text(message)
                        .font(Font.pretendard(.regular, size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Constants.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .top)
                }

                Image("Group 18")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 83)
                    .padding(.top, 20)
                    .padding(.bottom, 32)

                HStack(alignment: .center, spacing: 10) {
                    DeleteConfirmationButton(
                        title: cancelTitle,
                        foregroundColor: Constants.textInverse,
                        backgroundColor: Constants.surfaceDisable,
                        action: onCancel
                    )

                    DeleteConfirmationButton(
                        title: confirmTitle,
                        foregroundColor: Constants.textPrimary,
                        backgroundColor: Constants.primaryNormal,
                        action: onConfirm
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)
            .padding(.bottom, 16)
            .frame(width: 336, alignment: .top)
            .background(Constants.bgRegular)
            .cornerRadius(24)
        }
    }
}

private struct DeleteConfirmationButton: View {
    let title: String
    let foregroundColor: Color
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.pretendard(.semiBold, size: 16))
                .foregroundColor(foregroundColor)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(backgroundColor)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DeleteConfirmationOverlay(
        title: "녹음본을 삭제하시겠습니까?",
        onCancel: {},
        onConfirm: {}
    )
}

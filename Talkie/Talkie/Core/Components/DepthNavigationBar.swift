//
//  DepthNavigationBar.swift
//  Talkie
//
//  Created by DS on 7/23/26.
//

import SwiftUI

struct DepthNavigationBar<TrailingContent: View>: View {
    let title: String?
    let onBack: () -> Void
    @ViewBuilder let trailingContent: () -> TrailingContent

    private let horizontalPadding: CGFloat = 12
    private let topPadding: CGFloat = 12
    private let dividerTopSpacing: CGFloat = 12
    private let buttonSize: CGFloat = 36

    init(
        title: String? = nil,
        onBack: @escaping () -> Void,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent
    ) {
        self.title = title
        self.onBack = onBack
        self.trailingContent = trailingContent
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(alignment: .center) {
                    backButton

                    Spacer()

                    trailingContent()
                }

                if let title {
                    Text(title)
                        .font(Font.pretendard(.semiBold, size: 18))
                        .foregroundColor(Constants.textPrimary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)

            depthDivider
                .padding(.top, dividerTopSpacing)
        }
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Constants.grey100)
                .frame(width: buttonSize, height: buttonSize)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel("뒤로가기")
    }

    private var depthDivider: some View {
        TalkieDivider()
    }
}

extension DepthNavigationBar where TrailingContent == EmptyView {
    init(
        title: String? = nil,
        onBack: @escaping () -> Void
    ) {
        self.init(title: title, onBack: onBack) {
            EmptyView()
        }
    }
}

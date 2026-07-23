//
//  MainTabHeader.swift
//  Talkie
//
//  Created by DS on 7/23/26.
//

import SwiftUI

struct MainTabHeader<TrailingContent: View>: View {
    let title: String
    @ViewBuilder let trailingContent: () -> TrailingContent

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.pretendard(.bold, size: 24))
                .foregroundStyle(Constants.textPrimary)

            Spacer()

            trailingContent()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 68, maxHeight: 68, alignment: .center)
    }
}

extension MainTabHeader where TrailingContent == EmptyView {
    init(title: String) {
        self.init(title: title) {
            EmptyView()
        }
    }
}

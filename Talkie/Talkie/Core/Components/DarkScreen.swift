//
//  DarkScreen.swift
//  Talkie
//
//  Created by DS on 7/23/26.
//

import SwiftUI

struct DarkScreen<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            content
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    DarkScreen {
        Text("Talkie")
            .foregroundStyle(Constants.textPrimary)
    }
}

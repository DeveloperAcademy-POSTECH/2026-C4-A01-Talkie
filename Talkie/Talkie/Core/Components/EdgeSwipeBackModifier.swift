//
//  EdgeSwipeBackModifier.swift
//  Talkie
//
//  Created by DS on 7/24/26.
//

import SwiftUI

private struct EdgeSwipeBackModifier: ViewModifier {
    let onBack: () -> Void

    private let edgeActivationWidth: CGFloat = 28
    private let minimumSwipeDistance: CGFloat = 80
    private let maximumVerticalDrift: CGFloat = 60

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .global)
                    .onEnded { value in
                        guard value.startLocation.x <= edgeActivationWidth,
                              value.translation.width >= minimumSwipeDistance,
                              abs(value.translation.height) <= maximumVerticalDrift else {
                            return
                        }

                        onBack()
                    }
            )
    }
}

extension View {
    func edgeSwipeBack(_ onBack: @escaping () -> Void) -> some View {
        modifier(EdgeSwipeBackModifier(onBack: onBack))
    }
}

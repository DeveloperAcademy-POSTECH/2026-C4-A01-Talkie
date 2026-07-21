//
//  OnboardingPageIndicator.swift
//  Talkie
//
//  Created by DS on 7/20/26.
//

import SwiftUI

struct OnboardingPageIndicator: View {
    let pageCount: Int
    let selectedIndex: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        // TODO: Designer Page Indicator Style
    }
}

#Preview {
    OnboardingPageIndicator(pageCount: 3, selectedIndex: 0)
}

//
//  TalkieDivider.swift
//  Talkie
//
//  Created by DS on 7/23/26.
//

import SwiftUI

struct TalkieDivider: View {
    var color: Color = Constants.grey700
    var height: CGFloat = 0.5

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
            .frame(maxWidth: .infinity)
    }
}

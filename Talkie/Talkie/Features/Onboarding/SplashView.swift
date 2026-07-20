//
//  SplashView.swift
//  Talkie
//
//  Created by DS on 7/20/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 96, height: 96)
                .overlay {
                    Text("Logo")
                        .foregroundStyle(.secondary)
                }
                // TODO: Designer Logo
            
            Text("Talkie")
                .font(.title)
                .bold()
                // TODO: Designer App Name Style
        }
    }
}

#Preview {
    SplashView()
}

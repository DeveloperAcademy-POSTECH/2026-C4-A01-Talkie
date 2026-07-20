//
//  SplashView.swift
//  Talkie
//
//  Created by DS on 7/20/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 96, height: 96)
                    .overlay {
                        Text("Logo")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    // TODO: Designer Logo
                
                Text("Talkie")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.white)
                    // TODO: Designer App Name Style
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SplashView()
}

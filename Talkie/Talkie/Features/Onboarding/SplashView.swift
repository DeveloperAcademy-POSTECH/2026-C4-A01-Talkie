//
//  SplashView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            
            Image("Talkie_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SplashView()
}

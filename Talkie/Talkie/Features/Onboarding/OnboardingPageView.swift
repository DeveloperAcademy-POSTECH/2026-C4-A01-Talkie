//
//  OnboardingPageView.swift
//  Talkie
//
//  Created by DS on 7/20/26.
//

import SwiftUI

struct OnboardingPageView: View {
    let data: OnboardingData
    
    var body: some View {
        VStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.12))
                .frame(height: 350)
                .overlay {
                    Text("Illustration Placeholder")
                        .foregroundStyle(.white.opacity(0.6))
                }
                // TODO: Designer Illustration
            
            VStack(spacing: 12) {
                Text(data.title)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(data.description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

#Preview {
    OnboardingPageView(data: OnboardingData.pages[0])
        .background(Color.black)
}

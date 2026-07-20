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
                .fill(Color.gray.opacity(0.16))
                .frame(height: 350)
                .overlay {
                    Text("Illustration Placeholder")
                        .foregroundStyle(.secondary)
                }
                // TODO: Designer Illustration
            
            VStack(spacing: 12) {
                Text(data.title)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                
                Text(data.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

#Preview {
    OnboardingPageView(data: OnboardingData.pages[0])
}

//
//  OnboardingView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    
    @State private var selectedIndex = 0
    
    private let pages = OnboardingData.pages
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(data: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                bottomControls
            }
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
    }
}

private extension OnboardingView {
    var bottomControls: some View {
        VStack(spacing: 24) {
            OnboardingPageIndicator(
                pageCount: pages.count,
                selectedIndex: selectedIndex
            )
            
            if selectedIndex == pages.count - 1 {
                Button {
                    onFinish()
                } label: {
                    Text("다음으로")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            } else {
                HStack {
                    Spacer()
                    
                    Button("건너뛰기") {
                        onFinish()
                    }
                    .foregroundStyle(.white)
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    OnboardingView { }
}

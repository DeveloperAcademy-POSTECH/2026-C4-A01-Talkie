//
//  PhoneCardView.swift
//  Talkie
//
//  Created by DS on 7/19/26.
//

import SwiftUI

struct PhoneCardView: View {
    let scenario: Scenario?
    
    var body: some View {
        VStack(spacing: 24) {
            
            cardHeader
            
            scenarioInfo
                .padding(.bottom, 16)
            
            profilePlaceholder
                .padding(.bottom, 60)
            
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }
}

private extension PhoneCardView {
    var cardHeader: some View {
        HStack {
            
            Spacer()
            
            // 이번 단계에서는 시나리오 변경 기능 없이 버튼 UI만 제공합니다.
            Button { } label: {
                Text("변경")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Constants.main500)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }
    
    var profilePlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 140, height: 140)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
            
            Image("Profile")
                .resizable()
                .frame(width: 140, height: 140)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    var scenarioInfo: some View {
        if let scenario {
            VStack(spacing: 8) {
                Text(scenario.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("발화자 | \(scenario.callerName)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(1)
            }
        } else {
            VStack(spacing: 8){
                Text("엄마와의 통화")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 6){
                    Text("발화자")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 14)
                    
                    Text("엄마")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }

            }
        }
    }
    
    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(Constants.grey700)
            .overlay {
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
    }
}

#Preview {
    PhoneCardView(scenario: nil)
        .padding()
        .background(Constants.grey800)
}

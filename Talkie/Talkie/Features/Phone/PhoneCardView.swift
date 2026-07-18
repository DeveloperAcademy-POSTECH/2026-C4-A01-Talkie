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
            
            Spacer(minLength: 8)
            
            profilePlaceholder
            
            scenarioInfo
            
            Spacer(minLength: 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 360)
        .background(cardBackground)
    }
}

private extension PhoneCardView {
    var cardHeader: some View {
        HStack {
            Text("현재 시나리오")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
            
            Spacer()
            
            // 이번 단계에서는 시나리오 변경 기능 없이 버튼 UI만 제공합니다.
            Button { } label: {
                Text("변경")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Constants.main500)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
    }
    
    var profilePlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 112, height: 112)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
            
            Image(systemName: "person.fill")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(.white.opacity(0.44))
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
                
                Text("발화자: \(scenario.callerProfile.name)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(1)
            }
        } else {
            Text("선택된 시나리오가 없습니다.")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.64))
                .multilineTextAlignment(.center)
        }
    }
    
    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(Constants.grey700)
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
    }
}

#Preview {
    PhoneCardView(scenario: nil)
        .padding()
        .background(Constants.grey800)
}

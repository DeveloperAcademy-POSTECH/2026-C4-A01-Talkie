//
//  PhoneCardView.swift
//  Talkie
//
//  Created by DS on 7/19/26.
//

import SwiftUI

struct PhoneCardView: View {
    let scenario: ScenarioContent?
    let onChangeScenario: () -> Void

    init(
        scenario: ScenarioContent?,
        onChangeScenario: @escaping () -> Void = {}
    ) {
        self.scenario = scenario
        self.onChangeScenario = onChangeScenario
    }
    
    var body: some View {
        VStack(spacing: 0) {
            cardHeader

            Spacer(minLength: 0)

            scenarioInfo
                .padding(.bottom, 52)

            profilePlaceholder

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 440)
        .background(cardBackground)
    }
}

private extension PhoneCardView {
    var cardHeader: some View {
        HStack {
            
            Spacer()
            
            Button(action: onChangeScenario) {
                Text("변경")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.86))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Constants.grey800.opacity(0.72))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
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
                    .font(.system(size: 28, weight: .bold))
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
                Text("선택된 대화가 없습니다")
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
                    
                    Text("대화를 선택해주세요")
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

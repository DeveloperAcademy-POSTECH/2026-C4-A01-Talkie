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
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 112)

                scenarioInfo

                Spacer()
                    .frame(height: 62)

                profilePlaceholder

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            cardHeader
                .padding(.top, 32)
                .padding(.trailing, 32)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 411)
        .background(cardBackground)
    }
}

private extension PhoneCardView {
    var cardHeader: some View {
        Button(action: onChangeScenario) {
            Text("변경")
                .font(.pretendard(.bold, size: 14))
                .foregroundStyle(.white.opacity(0.86))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Constants.grey800.opacity(0.72))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, -12)
        .padding(.vertical, -12)
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
            
            Image("Profile")
                .resizable()
                .frame(width: 112, height: 112)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    var scenarioInfo: some View {
        if let scenario {
            VStack(spacing: 8) {
                Text(scenario.title)
                    .font(.pretendard(.bold, size: 24))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("발화자 | \(scenario.callerName)")
                    .font(.pretendard(.medium, size: 15))
                    .foregroundStyle(.white.opacity(0.42))
                    .lineLimit(1)
            }
        } else {
            VStack(spacing: 8){
                Text("선택된 대화가 없습니다")
                    .font(.pretendard(.semiBold, size: 24))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 6){
                    Text("발화자")
                        .font(.pretendard(.medium, size: 15))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 14)
                    
                    Text("대화를 선택해주세요")
                        .font(.pretendard(.medium, size: 15))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }

            }
        }
    }
    
    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 32)
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
}

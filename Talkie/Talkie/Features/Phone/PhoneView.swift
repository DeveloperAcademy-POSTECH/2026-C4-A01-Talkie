//
//  FakeCallView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI
import SwiftData

struct PhoneView: View {
    @Query(
        filter: #Predicate<Scenario> { scenario in
            scenario.isCurrentSelection == true
        },
        sort: \Scenario.createdAt,
        order: .reverse
    )
    private var currentScenarios: [Scenario]
    
    private var currentScenario: Scenario? {
        currentScenarios.first
    }

    var body: some View {
        ZStack {
            Constants.grey800
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 28) {
                Text("전화")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                
                PhoneCardView(
                    scenario: currentScenario
                )
                
                Button {
                    // 실제 통화 기능은 다음 단계에서 연결합니다.
                } label: {
                    Text("Make a call")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            currentScenario == nil
                            ? Constants.main500.opacity(0.24)
                            : Constants.main500
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .disabled(currentScenario == nil)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
        }
    }
}

#Preview {
    PhoneView()
}

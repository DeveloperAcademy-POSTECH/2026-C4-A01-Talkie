//
//  FakeCallView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI
import SwiftData

struct PhoneView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedDelay: Int = 5
//    let targetScenario: Scenario // 선택된 시나리오가 존재
    
    var body: some View {
        VStack {
            Text("\(selectedDelay)초 뒤 가짜 전화")
                .font(.headline)
            
            Button("전화 예약") {
                makeReservation()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func makeReservation() {
        let newReservation = CallReservation(
            delaySeconds: selectedDelay,
            scenario: targetScenario
            )
        
        modelContext.insert(newReservation)
    }
}

#Preview {
    PhoneView()
}

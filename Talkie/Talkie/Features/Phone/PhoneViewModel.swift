//
//  PhoneViewModel.swift
//  Talkie
//
//  Created by DS on 7/14/26.
//

import Foundation
import SwiftData
import Observation

@Observable
final class PhoneViewModel {

    var selectedScenario: Scenario?
    var delaySeconds: Int
    var errorMessage: String?

    init(
        selectedScenario: Scenario? = nil,
        delaySeconds: Int = 5,
        errorMessage: String? = nil
    ) {
        self.selectedScenario = selectedScenario
        self.delaySeconds = delaySeconds
        self.errorMessage = errorMessage
    }

    func selectDefaultScenarioIfNeeded(
        from scenarios: [Scenario]
    ) {
        guard selectedScenario == nil else {
            return
        }

        selectedScenario = scenarios.first
    }

    func createReservation(
        modelContext: ModelContext
    ) {
        errorMessage = nil

        guard let selectedScenario else {
            errorMessage = "통화에 사용할 시나리오를 선택해 주세요."
            return
        }

        guard delaySeconds > 0 else {
            errorMessage = "예약 시간은 1초 이상이어야 합니다."
            return
        }
        
        let scheduledDate = Date().addingTimeInterval(TimeInterval(delaySeconds))

        let newReservation = CallReservation(
            delaySeconds: delaySeconds,
            scheduledDate: scheduledDate,
            createdAt: Date(),
            status: "scheduled",
            scenario: selectedScenario
        )

        modelContext.insert(newReservation)

        do {
            try modelContext.save()
        } catch {
            modelContext.delete(newReservation)

            errorMessage = """
            전화 예약을 저장하지 못했습니다.
            \(error.localizedDescription)
            """
        }
    }
}

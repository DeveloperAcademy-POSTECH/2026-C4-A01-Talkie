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
    var errorMessage: String?

    init(
        selectedScenario: Scenario? = nil,
        errorMessage: String? = nil
    ) {
        self.selectedScenario = selectedScenario
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
    }
}

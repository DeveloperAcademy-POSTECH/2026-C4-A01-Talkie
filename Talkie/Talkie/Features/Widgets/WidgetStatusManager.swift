//
//  WidgetStatusManager.swift
//  Talkie
//
//  Created by DS on 7/22/26.
//

import Observation
import WidgetKit

@Observable
final class WidgetStatusManager {
    var isWidgetInstalled = false

    @MainActor
    func checkWidgetStatus() async {
        do {
            let configurations = try await WidgetCenter.shared.getCurrentConfigurations()
            isWidgetInstalled = !configurations.isEmpty
        } catch {
            print("Failed to fetch widget configurations: \(error)")
            isWidgetInstalled = false
        }
    }
}

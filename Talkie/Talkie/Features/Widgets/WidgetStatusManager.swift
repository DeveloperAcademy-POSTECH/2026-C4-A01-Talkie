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
            let configurations = try await fetchConfigurations()
            isWidgetInstalled = !configurations.isEmpty
        } catch {
            print("Failed to fetch widget configurations: \(error)")
            isWidgetInstalled = false
        }
    }

    private func fetchConfigurations() async throws -> [WidgetInfo] {
        try await withCheckedThrowingContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                switch result {
                case .success(let info):
                    continuation.resume(returning: info)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

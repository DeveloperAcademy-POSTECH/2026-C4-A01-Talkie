//
//  PreviewContainerFactory.swift
//  Talkie
//
//  Created by DS on 7/21/26.
//

import SwiftData

enum PreviewContainerFactory {
    @MainActor
    static func makeSafetyContactContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SafetyContact.self,
            configurations: config
        )
        
        return container
    }
}

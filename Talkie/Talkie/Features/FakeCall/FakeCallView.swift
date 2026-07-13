//
//  FakeCallView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI

struct FakeCallView: View {
    @Environment(\.dismiss) private var dismiss

    let callerName: String
    let relationship: String

    var body: some View {
        FakeCallEntryView(
            repository: MockFakeCallScriptRepository(
                displayName: callerName,
                relationship: relationship
            ),
            startsImmediately: true,
            onCallEnded: { dismiss() }
        )
    }
}

#Preview {
    FakeCallView(callerName: "엄마", relationship: "가족")
}

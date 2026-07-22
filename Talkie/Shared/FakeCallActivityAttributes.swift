//
//  FakeCallActivityAttributes.swift
//  Talkie
//
//  The app and Live Activity extension compile this shared file so ActivityKit
//  can encode and decode the same call state on both sides of the process boundary.
//

import ActivityKit
import Foundation

struct FakeCallActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// A fixed start date lets the system render an elapsed timer without
        /// receiving an update from the app every second.
        let startedAt: Date
    }

    /// Caller information does not change during a call, so it belongs to the
    /// immutable attributes rather than the frequently replaceable content state.
    let callerName: String
}

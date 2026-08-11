//
//  FakeCallLiveActivityManager.swift
//  Talkie
//
//  Owns the ActivityKit lifecycle for one active fake call. PhoneView remains
//  responsible for deciding when a call starts or ends; this service only mirrors
//  that state to system surfaces such as the Lock Screen and Dynamic Island.
//

import ActivityKit
import Foundation
import OSLog

@MainActor
final class FakeCallLiveActivityManager {
    static let shared = FakeCallLiveActivityManager()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.bk.spatial.talkie",
        category: "FakeCallLiveActivity"
    )

    /// Changes whenever a start or end request arrives. A delayed ActivityKit
    /// request can therefore detect that the call ended while it was starting.
    private var operationID = UUID()

    private init() { }

    func start(callerName: String, startedAt: Date) async {
        let currentOperationID = UUID()
        operationID = currentOperationID

        await endActivities(dismissalPolicy: .immediate)

        guard operationID == currentOperationID else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.info("Live Activities are disabled for this device or app.")
            return
        }

        let attributes = FakeCallActivityAttributes(callerName: callerName)
        let content = ActivityContent(
            state: FakeCallActivityAttributes.ContentState(startedAt: startedAt),
            staleDate: nil,
            relevanceScore: 100
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )

            // If the call ended while ActivityKit was creating the activity,
            // remove the late result immediately instead of leaving stale UI.
            guard operationID == currentOperationID else {
                await activity.end(nil, dismissalPolicy: .immediate)
                return
            }

            logger.info("Started fake-call Live Activity: \(activity.id, privacy: .public)")
        } catch {
            logger.error("Failed to start fake-call Live Activity: \(error.localizedDescription, privacy: .public)")
        }
    }

    func end() async {
        operationID = UUID()
        await endActivities(dismissalPolicy: .immediate)
    }

    private func endActivities(dismissalPolicy: ActivityUIDismissalPolicy) async {
        for activity in Activity<FakeCallActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: dismissalPolicy)
            logger.info("Ended fake-call Live Activity: \(activity.id, privacy: .public)")
        }
    }
}

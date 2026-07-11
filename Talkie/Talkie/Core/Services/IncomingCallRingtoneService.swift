//
//  IncomingCallRingtoneService.swift
//  Talkie
//

import UserNotifications

@MainActor
protocol IncomingCallRingtonePlaying: AnyObject {
    func prepareForRinging() async
    func startRinging(callerName: String) async
    func stopRinging()
}

@MainActor
final class IncomingCallRingtoneService: NSObject, IncomingCallRingtonePlaying {
    static let shared = IncomingCallRingtoneService()

    private static let requestIdentifier = "talkie.fake-call.incoming"
    private static let categoryIdentifier = "talkie.fake-call.category"

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    func configure() {
        notificationCenter.delegate = self
    }

    func prepareForRinging() async {
        _ = await canPlayNotificationSound()
    }

    func startRinging(callerName: String) async {
        stopRinging()

        guard await canPlayNotificationSound(), !Task.isCancelled else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = callerName
        content.body = "전화가 걸려옵니다."
        content.categoryIdentifier = Self.categoryIdentifier
        content.threadIdentifier = Self.categoryIdentifier
        content.sound = .defaultRingtone

        let request = UNNotificationRequest(
            identifier: Self.requestIdentifier,
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    func stopRinging() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [Self.requestIdentifier]
        )
        notificationCenter.removeDeliveredNotifications(
            withIdentifiers: [Self.requestIdentifier]
        )
    }

    private func canPlayNotificationSound() async -> Bool {
        var settings = await notificationCenter.notificationSettings()

        if settings.authorizationStatus == .notDetermined {
            let granted = (try? await notificationCenter.requestAuthorization(
                options: [.alert, .sound]
            )) ?? false

            guard granted else { return false }
            settings = await notificationCenter.notificationSettings()
        }

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return settings.soundSetting == .enabled
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }
}

extension IncomingCallRingtoneService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if notification.request.content.categoryIdentifier == "talkie.fake-call.category" {
            return [.sound]
        }

        return [.banner, .list, .sound]
    }
}

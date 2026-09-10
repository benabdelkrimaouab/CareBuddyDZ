//  CareBuddyDZ
//
//  Created by MAC on 30/5/2026.
//

import Foundation

import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    override init() {
        super.init()

        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {

        UNUserNotificationCenter.current()
            .requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { success, error in

                if success {
                    print("Permission granted")
                } else if let error = error {
                    print(error.localizedDescription)
                }
            }
    }

    func sendNotification(
        title: String,
        body: String
    ) {

        let content = UNMutableNotificationContent()

        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current()
            .add(request)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {

        return [.banner, .sound, .badge]
    }
}

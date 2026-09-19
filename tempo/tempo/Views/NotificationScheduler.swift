import Foundation
import UserNotifications

enum NotificationScheduler {
    static func schedule(_ requests: [NotificationRequest]) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            for request in requests {
                let content = UNMutableNotificationContent()
                content.title = request.title
                content.body = request.message
                if request.playsSound {
                    content.sound = .default
                }

                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: TimeInterval(max(request.secondsRemaining, 1)),
                    repeats: false
                )
                let notificationRequest = UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger)
                center.add(notificationRequest)
            }
        }
    }

    static func schedule(identifier: String, secondsRemaining: Int, title: String, message: String) {
        schedule([NotificationRequest(identifier: identifier, secondsRemaining: secondsRemaining, title: title, message: message, playsSound: true)])
    }

    static func cancel(_ identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    static func cancel(identifier: String) {
        cancel([identifier])
    }
}

struct NotificationRequest {
    let identifier: String
    let secondsRemaining: Int
    let title: String
    let message: String
    let playsSound: Bool // 진동 전용 큐는 여기가 false가 되도록 한다.
}

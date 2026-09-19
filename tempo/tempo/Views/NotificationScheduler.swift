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
                switch request.sound {
                case .none:
                    break
                case .default:
                    content.sound = .default
                case let .named(fileName):
                    // UNNotificationSound(named:)는 watchOS에서 아예 지원하지 않는다 —
                    // 이 케이스는 아이폰(커스텀 녹음 사운드, 이슈 #113)에서만 실제로
                    // 발생하고, 워치는 항상 .default만 쓰므로 여기 도달하지 않는다.
                    #if os(watchOS)
                    content.sound = .default
                    #else
                    content.sound = UNNotificationSound(named: UNNotificationSoundName(fileName))
                    #endif
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
        schedule([NotificationRequest(identifier: identifier, secondsRemaining: secondsRemaining, title: title, message: message, sound: .default)])
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
    let sound: NotificationSound
}

/// 알림에 사운드를 어떻게 붙일지. 진동 전용 큐는 `.none`, 시스템 기본음은 `.default`,
/// 특정 사운드 파일(기본 제공 `.wav` 또는 녹음을 변환한 `.caf`)을 쓰려면 `.named`를
/// 쓴다 — 파일명은 앱 번들이나 앱 컨테이너의 `Library/Sounds`에 있어야 한다(이슈 #113).
enum NotificationSound {
    case none
    case `default`
    case named(String)
}

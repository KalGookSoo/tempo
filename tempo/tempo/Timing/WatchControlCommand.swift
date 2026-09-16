import Foundation

struct WatchControlCommand: Codable {
    enum Action: String, Codable {
        case start, pause, resume, reset
        /// 워치에서 연동을 끊을 때 보낸다(#104) — 상태를 바꾸는 액션이 아니라
        /// 아이폰의 연동 플래그(`isWatchSyncEnabled`)만 끄라는 제어 신호다.
        case disconnect
    }

    let action: Action
    let sentAt: Date
}

import Foundation

struct WatchControlCommand: Codable {
    enum Action: String, Codable {
        case start, pause, resume, reset
    }

    let action: Action
    let sentAt: Date
}

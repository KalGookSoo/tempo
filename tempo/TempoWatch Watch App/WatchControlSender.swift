import Foundation
import WatchConnectivity

enum WatchControlSender {
    static func send(_ action: WatchControlCommand.Action) {
        guard WCSession.default.activationState == .activated else { return }
        let command = WatchControlCommand(action: action, sentAt: .now)
        guard let data = try? JSONEncoder().encode(command) else { return }
        try? WCSession.default.updateApplicationContext(["control": data])
    }
}

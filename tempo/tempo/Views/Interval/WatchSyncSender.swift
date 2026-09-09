import Foundation
import WatchConnectivity

/// WCSession.updateApplicationContext로 인터벌 실행 상태를 워치로 보낸다.
/// sendMessage는 양쪽 다 foreground여야 해서 부적합하다.
/// updateApplicationContext는 최신 값만 유지하고 워치가 나중에 앱을 열어도 받을 수 있어 이 용도에 맞다(#79).
final class WatchSyncSender: NSObject, WCSessionDelegate {
    static let shared = WatchSyncSender()

    override private init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(programName: String, config: IntervalConfig, runner: IntervalRunner) {
        guard WCSession.default.activationState == .activated else { return }

        let snapshot = IntervalWatchSnapshot(
            programName: programName,
            config: config,
            elapsedSeconds: runner.totalElapsed(at: .now),
            isPaused: runner.state == .paused,
            sentAt: .now
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? WCSession.default.updateApplicationContext(["snapshot": data])
    }

    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {}

    func sessionDidBecomeInactive(_: WCSession) {}

    func sessionDidDeactivate(_: WCSession) {
        WCSession.default.activate()
    }
}

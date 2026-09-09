import Combine
import Foundation
import WatchConnectivity

final class WatchSyncReceiver: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSyncReceiver()

    @Published private(set) var latestSnapshot: IntervalWatchSnapshot?

    override private init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {}

    /// 아이폰이 백그라운드여도, 워치 앱을 열면 마지막 컨텍스트를 여기로 받는다.
    func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["snapshot"] as? Data,
              let snapshot = try? JSONDecoder().decode(IntervalWatchSnapshot.self, from: data)
        else { return }

        Task { @MainActor in
            self.latestSnapshot = snapshot
        }
    }
}

extension IntervalWatchSnapshot {
    /// 이 스냅샷이 가리키는 지점 그대로 로컬 IntervalRunner를 재구성한다.
    /// sentAt을 기준으로 역산하기 때문에, 실제 도착 시각(네트워크 지연)과 무관하게 항상 정확한 elapsedSeconds를 재현한다.
    func makeRunner() -> IntervalRunner {
        let runner = IntervalRunner(config: config)
        let backdatedStart = sentAt.addingTimeInterval(-elapsedSeconds)
        runner.start(at: backdatedStart)
        if isPaused {
            runner.pause(at: sentAt)
        }
        return runner
    }
}

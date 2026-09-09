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

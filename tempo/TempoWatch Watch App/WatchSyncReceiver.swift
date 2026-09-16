import Combine
import Foundation
import OSLog
import WatchConnectivity

final class WatchSyncReceiver: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSyncReceiver()

    /// 배포된 빌드에서도 워치 실기기 콘솔로 확인할 수 있는 로그(이슈 #89).
    private static let logger = Logger(subsystem: "kr.me.seesaw.tempo.watchkitapp", category: "WatchSync")

    @Published private(set) var presets: [WatchPresetSnapshot] = []

    override private init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {
        refresh()
    }

    /// 아이폰이 마지막으로 보낸 프로그램 목록을 다시 읽어온다. updateApplicationContext는
    /// 마지막 값을 시스템이 계속 들고 있어서, 새 델리게이트 콜백을 기다리지 않고도 언제든
    /// 다시 조회할 수 있다 — "갱신" 버튼과 화면 진입 시 둘 다 이걸로 처리한다.
    func refresh() {
        guard let data = WCSession.default.receivedApplicationContext["presets"] as? Data else { return }
        decode(data)
    }

    /// 아이폰이 백그라운드여도, 워치 앱을 열면 마지막 컨텍스트를 여기로 받는다.
    func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["presets"] as? Data else { return }
        decode(data)
    }

    private func decode(_ data: Data) {
        guard let decoded = try? JSONDecoder().decode([WatchPresetSnapshot].self, from: data) else {
            Self.logger.error("아이폰에서 받은 프로그램 목록 디코딩 실패")
            return
        }
        Task { @MainActor in
            self.presets = decoded
        }
    }
}

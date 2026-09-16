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
        loadCachedContext()
    }

    /// 아이폰이 마지막으로 보낸 프로그램 목록을 다시 읽어온다. updateApplicationContext는
    /// 마지막 값을 시스템이 계속 들고 있어서, 새 델리게이트 콜백을 기다리지 않고도 언제든
    /// 다시 조회할 수 있다 — 아이폰과 연결이 안 돼 있어도(오프라인) 마지막으로 동기화된
    /// 목록을 그대로 보여줄 수 있어서, 화면을 열 때마다 이걸로 먼저 채운다.
    func loadCachedContext() {
        guard let data = WCSession.default.receivedApplicationContext["presets"] as? Data else { return }
        decode(data)
    }

    /// "갱신" 버튼: 캐시된 값을 다시 읽는 게 아니라, 지금 이 순간 아이폰에 실제로
    /// 다시 물어봐서 최신 프로그램 목록을 받아온다(요청-응답). 아이폰이 지금 reachable
    /// 하지 않으면 조용히 실패한다 — 마지막으로 받아둔 목록은 그대로 화면에 남는다.
    func requestRefresh() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else {
            Self.logger.notice("갱신 요청 취소: 아이폰과 연결돼 있지 않음(reachable=\(session.isReachable, privacy: .public))")
            return
        }
        session.sendMessage([:], replyHandler: { [weak self] reply in
            guard let data = reply["presets"] as? Data else { return }
            self?.decode(data)
        }, errorHandler: { error in
            Self.logger.error("갱신 요청 실패: \(error.localizedDescription, privacy: .public)")
        })
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

import Foundation
import OSLog
import WatchConnectivity

/// WCSession.updateApplicationContext로 프로그램(프리셋) 목록을 애플워치에 보낸다.
/// 워치는 이 목록을 받은 뒤로는 아이폰과 통신하지 않고 완전히 로컬로 실행하므로,
/// 여기서는 목록 전송 외에 실행 상태를 주고받지 않는다.
final class WatchSyncSender: NSObject, WCSessionDelegate {
    /// 배포된 빌드에서도 실기기 콘솔(Console.app)로 확인할 수 있는 로그(이슈 #89).
    /// 워치 연동은 실기기에서만 재현되는 문제가 잦았던 영역이라 진단 로그가 특히 중요하다.
    private static let logger = Logger(subsystem: "kr.me.seesaw.tempo", category: "WatchSync")

    static let shared = WatchSyncSender()

    override private init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    var isPairedButNotInstalled: Bool {
        WCSession.default.activationState == .activated
            && WCSession.default.isPaired
            && !WCSession.default.isWatchAppInstalled
    }

    func send(presets: [WatchPresetSnapshot]) {
        // updateApplicationContext는 페어링/설치 상태가 안 맞아도 에러 없이 그냥
        // 전달이 안 될 때가 있다 — 그러면 catch에도 안 걸려서 버튼을 눌러도 왜
        // 반응이 없는지 로그로 구분이 안 됐다. 매 호출마다 이 세 값을 무조건 남겨서,
        // 어느 분기를 탔는지 나중에라도 알 수 있게 한다.
        let session = WCSession.default
        Self.logger.notice(
            "send 호출: activationState=\(session.activationState.rawValue, privacy: .public) isPaired=\(session.isPaired, privacy: .public) isWatchAppInstalled=\(session.isWatchAppInstalled, privacy: .public)"
        )

        guard session.activationState == .activated else {
            Self.logger.error("전송 취소: WCSession이 아직 activated 상태가 아님")
            return
        }

        guard let data = try? JSONEncoder().encode(presets) else {
            Self.logger.error("프로그램 목록 인코딩 실패")
            return
        }
        do {
            try session.updateApplicationContext(["presets": data])
            Self.logger.notice("updateApplicationContext(presets) 호출 성공")
        } catch {
            Self.logger.error("updateApplicationContext(presets) 실패: \(error.localizedDescription, privacy: .public)")
        }
    }

    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {}

    /// isPaired/isWatchAppInstalled/watchDirectoryURL이 바뀔 때 시스템이 호출해준다.
    /// 이게 없으면 워치 앱이 설치/삭제되거나 페어링이 바뀌어도 앱이 그 사실을 알 방법이
    /// 없어서, 세션 활성화 시점에 캐시된 값이 stale한 채로 계속 쓰였다(#99와 유사한
    /// 워치 동기화 무반응 제보의 근본 원인으로 추정). 지금은 로그만 남기지만, 값이
    /// 바뀌었다는 사실 자체가 진단에 중요하다.
    func sessionWatchStateDidChange(_ session: WCSession) {
        Self.logger.notice(
            "sessionWatchStateDidChange: activationState=\(session.activationState.rawValue, privacy: .public) isPaired=\(session.isPaired, privacy: .public) isWatchAppInstalled=\(session.isWatchAppInstalled, privacy: .public)"
        )
    }

    func sessionDidBecomeInactive(_: WCSession) {}

    func sessionDidDeactivate(_: WCSession) {
        WCSession.default.activate()
    }
}

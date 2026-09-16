import Combine
import Foundation
import OSLog
import WatchConnectivity

final class WatchSyncReceiver: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSyncReceiver()

    /// 배포된 빌드에서도 워치 실기기 콘솔로 확인할 수 있는 로그(이슈 #89).
    private static let logger = Logger(subsystem: "kr.me.seesaw.tempo.watchkitapp", category: "WatchSync")

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
        guard let data = applicationContext["snapshot"] as? Data else { return }
        guard let snapshot = try? JSONDecoder().decode(IntervalWatchSnapshot.self, from: data) else {
            Self.logger.error("아이폰에서 받은 snapshot 페이로드 디코딩 실패")
            return
        }

        Task { @MainActor in
            self.latestSnapshot = snapshot
        }
    }
}

extension IntervalWatchSnapshot {
    /// 이 스냅샷이 가리키는 지점 그대로 로컬 IntervalRunner를 재구성한다.
    /// 앵커는 sentAt(아이폰 시계)이 아니라 이 기기(워치) 자신의 시계로 잡는다 —
    /// elapsedSeconds는 보낸 시점까지 이미 지난 시간(하나의 값)이라 어느 시계를
    /// 기준으로 역산하든 그 값 자체는 그대로 쓸 수 있고, 이렇게 하면 실행 중
    /// (RUNNING) 상태에서 이후 매 프레임 이 기기 자신의 Date.now()와 비교해도
    /// 항상 자기 자신의 시계끼리만 비교하게 된다. 원래처럼 sentAt을 앵커로 쓰면
    /// 일시정지처럼 그 순간 한 번만 계산하고 끝나는 경우는 괜찮지만, 실행 중
    /// 상태는 두 기기 시계가 조금만 어긋나도 그 오차가 계속 화면에 드러난다
    /// ("재개하면 어긋나고 안 풀린다"는 제보의 원인이었다).
    /// isIdle이면(리셋 직후) start(at:)를 아예 안 불러서 IntervalRunner가 기본으로
    /// 갖는 .idle 상태 그대로 둔다 — 안 그러면 elapsedSeconds == 0인 리셋 스냅샷이
    /// "방금 시작함"과 구분이 안 돼서, 워치가 첫 구간을 곧바로 카운트다운하기
    /// 시작해버린다(이슈 #91).
    func makeRunner() -> IntervalRunner {
        let runner = IntervalRunner(config: config)
        guard !isIdle else { return runner }

        let receivedAt = Date.now
        let backdatedStart = receivedAt.addingTimeInterval(-elapsedSeconds)
        runner.start(at: backdatedStart)
        if isPaused {
            runner.pause(at: receivedAt)
        }
        return runner
    }
}

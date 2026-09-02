import UIKit

/// 실행 화면이 보이는 동안 계속 "아직 필요하다"는 신호(`renew`)를 보내야 화면 자동
/// 잠금이 계속 방지되는 TTL 방식의 리스(lease). 신호가 끊기면 — 탭 전환, 홈 화면 이동,
/// 백그라운드 진입 등 어떤 경로로 화면을 벗어났든 상관없이 — `gracePeriod` 뒤 자동으로
/// 자동 잠금이 복구된다.
///
/// 이전엔 `onChange`/`onDisappear`로 "화면을 벗어나는 모든 경로"를 일일이 잡아야 했는데,
/// `TabView`가 안 보이는 탭의 뷰를 뷰 계층에서 제거하지 않고 살려두는 경우가 있어서
/// 탭 전환만으로는 `onDisappear`가 안 불려 화면이 계속 안 꺼지는 문제가 있었다(이슈 #53).
/// 실행 화면들은 이미 `TimelineView`로 화면에 보일 때만 주기적으로 다시 그려지므로
/// (애플이 배터리 절약을 위해 안 보이면 틱 자체를 멈추도록 설계함), 그 틱마다 `renew()`를
/// 부르기만 하면 "화면에 보이는 동안"이라는 조건을 별도로 추적할 필요가 없다.
enum ScreenAwakeLease {
    private static var expireTask: Task<Void, Never>?

    static func renew(gracePeriod: TimeInterval = 5) {
        UIApplication.shared.isIdleTimerDisabled = true

        expireTask?.cancel()
        expireTask = Task {
            try? await Task.sleep(for: .seconds(gracePeriod))
            guard !Task.isCancelled else { return }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

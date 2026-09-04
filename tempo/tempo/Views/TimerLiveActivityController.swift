import ActivityKit
import Foundation

/// 타이머/스톱워치 실행 상태를 Live Activity(잠금화면·알림센터·다이나믹 아일랜드)로
/// 내보낸다(이슈 #52). `TimerEngine`/`StopwatchEngine`과 마찬가지로 Date 기반이라,
/// 시작/일시정지/재개 시점에만 상태를 갱신해주면 그 사이 남은/경과 시간은 위젯이
/// 알아서 실시간으로 그려준다 — 앱이 백그라운드거나 화면이 꺼져 있어도 마찬가지다.
///
/// 타이머와 스톱워치가 동시에 실행될 수 있어서(서로 다른 탭), `kind`별로 별도
/// Activity를 관리한다 — `NotificationScheduler`가 `identifier`로 구분하는 것과
/// 같은 이유다.
enum TimerLiveActivityController {
    enum Kind: Hashable {
        case timer
        case stopwatch
    }

    private static var activities: [Kind: Activity<TimerActivityAttributes>] = [:]

    /// Live Activity가 없으면 새로 시작하고, 이미 있으면 상태만 갱신한다.
    static func start(
        kind: Kind,
        title: String,
        displayMode: TimerActivityAttributes.ContentState.DisplayMode,
        referenceDate: Date,
        staticText: String,
        statusLabel: String
    ) {
        let state = TimerActivityAttributes.ContentState(
            displayMode: displayMode,
            referenceDate: referenceDate,
            staticText: staticText,
            statusLabel: statusLabel
        )

        if let activity = activities[kind] {
            Task {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        activities[kind] = try? Activity.request(
            attributes: TimerActivityAttributes(title: title),
            content: ActivityContent(state: state, staleDate: nil)
        )
    }

    static func end(kind: Kind) {
        guard let activity = activities[kind] else { return }
        activities[kind] = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

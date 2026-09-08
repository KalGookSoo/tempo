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
    ///
    /// `staleDate`를 넘기면, 그 시각이 지나는 순간 앱이 백그라운드거나 화면이 꺼져 있어도
    /// 시스템이 알아서 위젯 쪽 `context.isStale`을 true로 바꿔준다 — 카운트다운 타이머처럼
    /// "화면을 안 보고 있어도 스스로 끝나는" 경우, 그 순간에 코드를 실행해줄 앱 프로세스가
    /// 없어도 위젯이 완료 상태로 얼어붙을 수 있게 하는 용도다(이슈 #87). 자연 종료 시점이
    /// 없는 스톱워치·일시정지 상태는 `nil`로 둔다.
    static func start(
        kind: Kind,
        title: String,
        displayMode: TimerActivityAttributes.ContentState.DisplayMode,
        referenceDate: Date,
        staleDate: Date? = nil,
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
                await activity.update(ActivityContent(state: state, staleDate: staleDate))
            }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        activities[kind] = try? Activity.request(
            attributes: TimerActivityAttributes(title: title),
            content: ActivityContent(state: state, staleDate: staleDate)
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

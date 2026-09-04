import ActivityKit
import Foundation

/// 잠금화면·알림센터·다이나믹 아일랜드에 실시간으로 보여줄 실행 상태(이슈 #52).
/// 타이머와 스톱워치가 이 하나의 타입을 공유한다 — 인터벌은 이번 범위에 포함하지
/// 않는다(#21이 애초에 백그라운드 실행을 타이머/스톱워치로 한정한 것과 같은 이유).
///
/// 앱 본체와 위젯 익스텐션(`TempoWidget`) 양쪽 타겟이 이 타입을 알아야 해서, 두
/// 타겟이 함께 참조하는 `Shared/` 폴더에 둔다.
struct TimerActivityAttributes: ActivityAttributes {
    /// 실행 내내 값이 유지되는 정적 속성. "타이머"/"스톱워치" 또는 사용자가 지정한
    /// 타이머 레이블이 들어간다.
    var title: String

    struct ContentState: Codable, Hashable {
        enum DisplayMode: String, Codable {
            /// `referenceDate`까지 남은 시간을 실시간으로 카운트다운한다.
            case countdown
            /// `referenceDate`부터 지난 시간을 실시간으로 카운트업한다.
            case countUp
            /// 일시정지처럼 시간이 안 흐르는 상태. `staticText`를 그대로 보여준다.
            case paused
        }

        var displayMode: DisplayMode
        var referenceDate: Date
        var staticText: String
        var statusLabel: String
    }
}

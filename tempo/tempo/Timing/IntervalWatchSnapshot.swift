import Foundation

/// 아이폰에서 애플워치로 전송하는 인터벌 실행 스냅샷. WCSession의
/// updateApplicationContext로 보낼 최소 데이터.
/// 설정값 + "지금까지 경과한 시간"만 담고, 워치는 이걸로 로컬 IntervalRunner를 재구성해서 스스로 카운트한다.
struct IntervalWatchSnapshot: Codable {
    let programName: String
    let config: IntervalConfig
    let elapsedSeconds: TimeInterval
    let isPaused: Bool
    /// 리셋 직후(`TimerState.idle`)인지 여부. 이게 없으면 리셋 스냅샷도
    /// elapsedSeconds == 0인 "방금 시작함"과 구분이 안 돼서, 워치가 리셋을
    /// 받고도 첫 구간을 곧바로 카운트다운하기 시작해버렸다(이슈 #91).
    let isIdle: Bool
    let sentAt: Date
}

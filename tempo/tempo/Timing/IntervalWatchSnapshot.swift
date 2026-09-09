import Foundation

/// 아이폰에서 애플워치로 전송하는 인터벌 실행 스냅샷. WCSession의
/// updateApplicationContext로 보낼 최소 데이터.
/// 설정값 + "지금까지 경과한 시간"만 담고, 워치는 이걸로 로컬 IntervalRunner를 재구성해서 스스로 카운트한다.
struct IntervalWatchSnapshot: Codable {
    let programName: String
    let config: IntervalConfig
    let elapsedSeconds: TimeInterval
    let isPaused: Bool
    let sentAt: Date
}

import Foundation

/// 아이폰 프로그램 목록(`TimerPreset`)을 애플워치로 보낼 때 쓰는 최소 스냅샷.
/// `TimerPreset`은 SwiftData 모델이라 SwiftData 의존이 없는 워치 타겟에서 직접 쓸 수
/// 없어서, 실행에 필요한 값만 뽑아 Codable로 감싼다. 워치는 이 값을 받아 프로그램을
/// 고르면 그 뒤로는 아이폰과 통신하지 않고 완전히 로컬로 실행한다.
struct WatchPresetSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let config: IntervalConfig
}

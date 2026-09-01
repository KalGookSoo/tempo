import Foundation

/// 인터벌 탭 안에서만 쓰는 값 기반 라우트. 인터벌 탭은 자체 `NavigationStack`을 가지므로
/// 탭 전환과 무관하게 이 경로가 유지된다. docs/navigation-structure.md 참고.
enum IntervalRoute: Hashable {
    case new
    case programs
    case programDetail(id: String)
    case programEdit(id: String)
    case run(programID: String)
}

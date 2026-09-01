import SwiftUI

/// 아이패드 가로 모드처럼 화면이 넓을 때, 콘텐츠가 화면 폭 그대로 늘어나지 않도록 태블릿
/// 세로 폭(768pt) 정도로 제한하고 가운데 정렬한다. `tempoApp`의 `TabView` 루트 하나에
/// 적용해 앱 전체 화면에 일괄로 걸리게 한다 — 타이머/스톱워치/인터벌 실행 화면도 지금은
/// 함께 제한되는데, 이 화면들은 전체 화면을 쓰는 게 맞아 나중에 별도의 전체 화면 모드로
/// 빼야 한다. 이슈 #45 참고.
extension View {
    func constrainedWidth() -> some View {
        frame(maxWidth: 768)
            .frame(maxWidth: .infinity)
    }
}

import SwiftUI

/// 아이패드 가로 모드처럼 화면이 넓을 때, 정보 제공 위주 화면(상세/설정 등)의 콘텐츠가
/// 화면 폭 그대로 늘어나지 않도록 태블릿 세로 폭(768pt) 정도로 제한하고 가운데 정렬한다.
/// 타이머/스톱워치/인터벌 실행처럼 화면 전체를 쓰는 화면에는 적용하지 않는다. 이슈 #45 참고.
extension View {
    func constrainedWidth() -> some View {
        frame(maxWidth: 768)
            .frame(maxWidth: .infinity)
    }
}

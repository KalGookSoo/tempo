import SwiftUI

/// 아이패드 가로 모드처럼 화면이 넓을 때, 콘텐츠가 화면 폭 그대로 늘어나지 않도록 태블릿
/// 세로 폭(768pt) 정도로 제한하고 가운데 정렬한다. `tempoApp`의 `TabView` 루트 하나에
/// 적용해 앱 전체 화면에 일괄로 걸리게 한다.
///
/// 타이머/스톱워치/인터벌 실행 화면도 지금은 함께 제한된다 — 화면별로만 적용하고 실행
/// 화면은 빼려고도 해봤지만(이슈 #47), 자식 뷰는 부모(TabView)가 이미 제한한 프레임보다
/// 넓어질 수 없어서 modifier로 자동 예외 처리하는 방법이 없었다. 대신 나중에 그 화면들에
/// 수동 "전체 화면" 버튼을 추가해 사용자가 직접 전환하게 할 계획이다(이슈 #47).
extension View {
    func constrainedWidth() -> some View {
        frame(maxWidth: 768)
            .frame(maxWidth: .infinity)
    }
}

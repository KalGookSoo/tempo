import SwiftUI
import UIKit

/// `NavigationStack` 푸시 전환 애니메이션이 실제로 끝나는 시점을 알려주는 숨은 뷰.
/// SwiftUI 자체에는 이 신호가 없어서, `UIViewControllerRepresentable`로 만든 빈
/// `UIViewController`를 화면에 심어 `transitionCoordinator`의 완료 콜백을 받는다.
///
/// 전환이 끝나기 전에 `.sheet`를 띄우면 UIKit이 프레젠테이션을 즉시 취소해버려서,
/// 인터벌 세트 시간 팝업이 프로그램 수정/새 프로그램 화면 진입 직후에만 "열렸다
/// 바로 닫히는" 버그가 있었다. `onComplete`가 불리기 전까지는 팝업을 열지 않도록
/// 막는 용도로 쓴다.
struct NavigationTransitionGate: UIViewControllerRepresentable {
    let onComplete: () -> Void

    func makeUIViewController(context _: Context) -> GateViewController {
        let controller = GateViewController()
        controller.onComplete = onComplete
        return controller
    }

    func updateUIViewController(_: GateViewController, context _: Context) {}

    final class GateViewController: UIViewController {
        var onComplete: (() -> Void)?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let coordinator = transitionCoordinator else {
                onComplete?()
                return
            }
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.onComplete?()
            }
        }
    }
}

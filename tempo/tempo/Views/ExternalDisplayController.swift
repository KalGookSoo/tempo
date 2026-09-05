import SwiftUI
import UIKit

/// 실행 화면(타이머/스톱워치/인터벌)이 지금 보여주고 있는 내용을, 연결된 외부
/// 디스플레이(TV)에도 별도 창으로 그린다. 이슈 #62 참고.
///
/// 사용자가 제어센터의 "화면 미러링"으로 외부 디스플레이를 연결하면 iOS가
/// `UIScreen`을 만들어주는데, 폰 화면을 그대로 복제하는 대신 이 컨트롤러가 그
/// `UIScreen` 위에 별도 창을 올려서 컨트롤 버튼 없이 표시 전용으로 다시 그린다.
/// (원래는 앱 안의 AirPlay 캐스팅 버튼으로 직접 연결을 시작하려 했으나, 이
/// 앱처럼 지속 재생 미디어 세션이 없는 경우 `AVRoutePickerView`로는 화면
/// 캐스팅 자체가 안 된다는 게 실기기 테스트로 확인돼 이슈 #63에서 폐기했다 —
/// 지금은 제어센터 미러링으로 연결하는 경로만 지원한다.)
///
/// 실행 화면들은 매 틱마다(`ScreenAwakeLease.renew()`를 부르는 것과 같은 지점에서)
/// `update(_:)`로 지금 보여줄 내용을 이 컨트롤러에 알려준다. 현재는 마지막으로
/// 화면에 보이고 있던 탭의 내용이 그대로 남는다 — 예를 들어 스톱워치 탭을 보다가
/// 타이머 탭으로 전환하면, 타이머 탭이 처음 틱을 그릴 때까지는 TV에 스톱워치의
/// 마지막 값이 잠깐 남을 수 있다. 세 화면이 동시에 하나의 외부 디스플레이를
/// 공유해서 생기는 알려진 한계이며, 필요하면 화면 전환 시 명시적으로 지우는
/// 방식으로 후속 개선한다.
@Observable
final class ExternalDisplayController: NSObject {
    static let shared = ExternalDisplayController()

    struct Content {
        let primaryText: String
        let statusLabel: String?
        let statusColor: Color
        let secondaryText: String?
    }

    private(set) var content: Content?
    private var window: UIWindow?

    override private init() {
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenDidConnect),
            name: UIScreen.didConnectNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenDidDisconnect),
            name: UIScreen.didDisconnectNotification, object: nil
        )
        if let external = UIScreen.screens.first(where: { $0 != UIScreen.main }) {
            attach(to: external)
        }
    }

    func update(_ content: Content?) {
        self.content = content
    }

    @objc private func screenDidConnect(_ notification: Notification) {
        guard let screen = notification.object as? UIScreen else { return }
        attach(to: screen)
    }

    @objc private func screenDidDisconnect(_: Notification) {
        window = nil
    }

    private func attach(to screen: UIScreen) {
        let window = UIWindow(frame: screen.bounds)
        window.screen = screen
        window.rootViewController = UIHostingController(rootView: ExternalDisplayView())
        window.isHidden = false
        self.window = window
    }
}

/// 외부 디스플레이(TV)에 실제로 그려지는 전용 화면. 폰 화면과 같은 "큰 숫자 +
/// 상태 배지"(`RunningDisplayView`)를 재사용하되, 컨트롤 버튼 없이 표시만 한다.
private struct ExternalDisplayView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let content = ExternalDisplayController.shared.content {
                RunningDisplayView(
                    primaryText: content.primaryText,
                    statusLabel: content.statusLabel,
                    statusColor: content.statusColor,
                    secondaryText: content.secondaryText,
                    fontSize: 220
                )
            }
        }
    }
}

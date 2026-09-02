import Foundation
import SwiftUI
import UIKit

/// 타이머/스톱워치/인터벌 실행 화면이 `running` 상태일 때 iOS 자동 잠금을 막는다.
/// `isAwake`가 false로 바뀌거나 화면이 사라지면 반드시 원래대로 되돌려서, 다른
/// 화면에서 기기가 계속 안 잠기는 부작용이 없게 한다. 이슈 #48 참고.
extension View {
    func keepScreenAwake(while isAwake: Bool) -> some View {
        onChange(of: isAwake) { _, newValue in
            UIApplication.shared.isIdleTimerDisabled = newValue
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

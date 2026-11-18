import MediaPlayer
import SwiftUI

/// iPhone의 시스템 미디어 음량을 사용자가 직접 조절하게 하는 SwiftUI 래퍼.
/// 앱이 음량을 강제로 바꾸지 않고, `MPVolumeView`가 제공하는 시스템 컨트롤을 그대로 쓴다.
struct SystemMediaVolumeSlider: UIViewRepresentable {
    func makeUIView(context _: Context) -> MPVolumeView {
        let volumeView = MPVolumeView()
        volumeView.showsRouteButton = false
        volumeView.showsVolumeSlider = true
        return volumeView
    }

    func updateUIView(_: MPVolumeView, context _: Context) {}
}

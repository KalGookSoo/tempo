import AVKit
import SwiftUI

/// `AVRoutePickerView`를 SwiftUI에서 쓰기 위한 얇은 래퍼. 탭하면 시스템이 제공하는
/// "AirPlay & Bluetooth Devices" 시트가 뜬다. `prioritizesVideoDevices`를 켜서
/// 오디오 스피커보다 화면 캐스팅(AirPlay 비디오)이 가능한 기기를 우선 보여준다.
/// 실행 화면(타이머/스톱워치/인터벌) 툴바가 공유한다. 이슈 #63 참고.
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context _: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.prioritizesVideoDevices = true
        view.tintColor = .label
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_: AVRoutePickerView, context _: Context) {}
}

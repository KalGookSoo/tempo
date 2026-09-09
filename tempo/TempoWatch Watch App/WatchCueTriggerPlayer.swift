import AVFoundation
import Foundation
import WatchKit

/// 아이폰의 CueTriggerPlayer에 해당하는 워치 전용 재생기.
/// 이번 범위에서는 CueConfig(사운드/진동 커스터마이징)를 워치까지 전송하지 않으므로,
/// 이벤트가 발생하면 무조건 진동 + 비프를 함께 재생하는 것으로 단순화한다(#81).
enum WatchCueTriggerPlayer {
    private static var player: AVAudioPlayer?

    static func play() {
        WKInterfaceDevice.current().play(.notification)

        guard let url = Bundle.main.url(forResource: "beep", withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url)
        else { return }

        player.prepareToPlay()
        player.play()
        self.player = player // 재생 끝나기 전에 해제되지 않도록 강한 참조 유지
    }
}

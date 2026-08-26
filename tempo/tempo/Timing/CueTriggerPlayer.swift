//
//  CueTriggerPlayer.swift
//  tempo
//

import AudioToolbox
import UIKit

/// `CueConfig.Event`를 실제 사운드/진동으로 재생한다. MVP는 사용자가 고른 `SoundAsset`
/// 파일(#8/#16에서 실제로 채워짐)을 아직 재생하지 않고, 시스템 기본 사운드로 대체한다 —
/// `docs/timer-functional-spec.md` "MVP는 기본 사운드와 진동을 제공한다"에 해당.
/// `soundAssetID`가 채워지기 시작하면 이 타입만 바꾸면 된다(호출부는 그대로).
enum CueTriggerPlayer {
    /// 시스템 기본 사운드("Tock"). 실제 번들 사운드가 생기기 전까지의 자리표시자.
    private static let placeholderSystemSoundID: SystemSoundID = 1057

    static func play(_ event: CueConfig.Event) {
        if event.mode.playsSound {
            AudioServicesPlaySystemSound(placeholderSystemSoundID)
        }
        if event.mode.playsVibration {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
    }
}

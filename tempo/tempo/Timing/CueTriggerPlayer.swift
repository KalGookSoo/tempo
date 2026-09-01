import AudioToolbox
import AVFoundation
import UIKit

/// `CueConfig.Event`를 실제 사운드/진동으로 재생한다. `soundAsset`을 넘기면 그 파일을
/// 재생하고(`kind == .builtin`은 앱 번들에서, `.imported`/`.recorded`는 문서 디렉터리에서
/// 찾는다), 못 찾거나 안 넘기면 시스템 기본 사운드로 대체한다. 호출부(`IntervalRunView`/
/// `TimerView`)가 `event.soundAssetID` 또는 이벤트 종류별 기본 사운드로 `SoundAsset`을
/// 조회해서 넘겨준다. docs/timer-functional-spec.md "기본 사운드" 참고.
enum CueTriggerPlayer {
    /// 실제 사운드 에셋을 못 찾았을 때의 대체 시스템 사운드("Tock").
    private static let placeholderSystemSoundID: SystemSoundID = 1057

    /// 재생 중인 플레이어들을 강한 참조로 들고 있는다. 하나만 들고 있으면 같은 틱에
    /// 이벤트가 두 개 겹칠 때(예: 구간 종료 + 다음 구간 시작) 나중 재생이 먼저 재생 중이던
    /// 플레이어를 밀어내 소리가 끊겼다 — 배열로 여러 개를 동시에 재생하게 한다(이슈 참고:
    /// 알림초가 구간 길이보다 길면 시작 알림과 카운트다운 알림이 같은 틱에 겹칠 수 있음).
    private static var activePlayers: [AVAudioPlayer] = []

    /// 앱 시작 시 한 번 호출해서 오디오 세션을 미리 활성화한다. 첫 재생 시 발생하는
    /// 하드웨어 예열 지연(이슈 #30)을 앱 실행 초반으로 옮겨, 인터벌 실행 화면 진입
    /// 시점에는 이미 준비된 상태가 되게 한다.
    static func prewarmAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    static func play(_ event: CueConfig.Event, soundAsset: SoundAsset? = nil) {
        if event.mode.playsSound {
            if let url = resolvedURL(for: soundAsset) {
                playFile(at: url)
            } else {
                AudioServicesPlaySystemSound(placeholderSystemSoundID)
            }
        }
        if event.mode.playsVibration {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
    }

    private static func resolvedURL(for soundAsset: SoundAsset?) -> URL? {
        guard let soundAsset, let relativePath = soundAsset.relativePath else { return nil }

        switch soundAsset.kind {
        case .builtin:
            let name = (relativePath as NSString).deletingPathExtension
            let ext = (relativePath as NSString).pathExtension
            return Bundle.main.url(forResource: name, withExtension: ext.isEmpty ? nil : ext)
        case .imported, .recorded:
            guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }
            return documents.appendingPathComponent(relativePath)
        }
    }

    private static func playFile(at url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            activePlayers.removeAll { !$0.isPlaying }
            activePlayers.append(player)
        } catch {
            AudioServicesPlaySystemSound(placeholderSystemSoundID)
        }
    }
}

import AVFoundation
import Foundation

/// 마이크 권한 상태.
enum MicrophonePermissionStatus {
    case undetermined
    case granted
    case denied
}

/// 알림 큐용 사운드를 마이크로 녹음하고 미리듣기한다. `AVAudioSession`/`AVAudioRecorder`/
/// `AVAudioPlayer`의 얇은 래퍼. 화면(`SettingsRecordingsView`)은 이 클래스를 통해서만
/// 오디오 하드웨어를 다룬다. 재생 종료를 감지해 `previewingAssetID`를 해제하려고
/// `AVAudioPlayerDelegate`를 채택한다(이슈 #28).
@Observable
final class SoundRecorder: NSObject {
    private(set) var isRecording = false
    private(set) var permissionStatus: MicrophonePermissionStatus = .undetermined
    /// 지금 미리듣기 재생 중인 `SoundAsset.id`. 재생 중이 아니면 `nil`.
    private(set) var previewingAssetID: UUID?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var pendingID: UUID?

    override init() {
        super.init()
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined:
            permissionStatus = .undetermined
        case .denied:
            permissionStatus = .denied
        case .granted:
            permissionStatus = .granted
        @unknown default:
            permissionStatus = .denied
        }
    }

    func requestPermission() async {
        let granted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        permissionStatus = granted ? .granted : .denied
    }

    /// 녹음을 시작한다. 새 `SoundAsset.id`를 만들어 그 id 기반 파일에 쓴다.
    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true)

        let id = UUID()
        let url = try RecordedSoundFileStore.fileURL(for: id)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.record()
        self.recorder = recorder
        pendingID = id
        isRecording = true
    }

    /// 녹음을 멈추고 방금 만든 파일의 id/길이를 반환한다. 호출부가 이 값으로
    /// `SoundAssetRepository.createRecordedAsset`을 호출해 메타데이터를 저장하거나,
    /// 사용자가 취소하면 `RecordedSoundFileStore.deleteFile(for:)`로 지운다.
    func stopRecording() -> (id: UUID, durationMs: Int)? {
        guard let recorder, let pendingID else { return nil }
        let durationMs = Int(recorder.currentTime * 1000)
        recorder.stop()
        self.recorder = nil
        self.pendingID = nil
        isRecording = false
        return (pendingID, durationMs)
    }

    /// 녹음을 미리듣기한다. 같은 항목을 다시 탭하면 멈춘다. 무음 스위치와 무관하게 항상
    /// 스피커로 들리도록 재생 전용 세션으로 전환한다(이슈 #28).
    func preview(_ asset: SoundAsset) {
        if previewingAssetID == asset.id {
            player?.stop()
            player = nil
            previewingAssetID = nil
            return
        }

        guard let url = try? RecordedSoundFileStore.fileURL(for: asset.id) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        guard let newPlayer = try? AVAudioPlayer(contentsOf: url) else { return }
        newPlayer.delegate = self
        player = newPlayer
        previewingAssetID = asset.id
        newPlayer.play()
    }
}

extension SoundRecorder: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully _: Bool) {
        Task { @MainActor in
            guard self.player === player else { return }
            self.previewingAssetID = nil
        }
    }
}

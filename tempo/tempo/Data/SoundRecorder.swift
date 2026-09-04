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
    /// 녹음 최대 길이. 알림음으로 쓰기엔 이보다 길면 운동에 방해된다는 판단으로
    /// 5초로 제한한다 — 도달하면 자동으로 정지한다. 이슈 #64 참고.
    static let maxDuration: TimeInterval = 5

    private(set) var isRecording = false
    private(set) var permissionStatus: MicrophonePermissionStatus = .undetermined
    /// 지금 미리듣기 재생 중인 `SoundAsset.id`. 재생 중이 아니면 `nil`.
    private(set) var previewingAssetID: UUID?
    /// 녹음 중 실시간으로 갱신되는 경과 시간(초). 녹음 중이 아니면 0이다.
    private(set) var elapsedTime: TimeInterval = 0
    /// 녹음 중 실시간으로 쌓이는 음량 레벨(0...1) 샘플 — 파형을 그리는 데 쓴다.
    /// 정지 후에도 다음 녹음을 시작하기 전까지는 방금 녹음한 값이 그대로 남는다.
    private(set) var levelSamples: [Float] = []
    /// 녹음이 끝나면(수동 정지든 최대 길이 도달로 자동 정지든) 채워지는 결과.
    private(set) var lastRecordingResult: (id: UUID, durationMs: Int)?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var pendingID: UUID?
    private var meterTimer: Timer?

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
        recorder.isMeteringEnabled = true
        recorder.record()
        self.recorder = recorder
        pendingID = id
        isRecording = true
        elapsedTime = 0
        levelSamples = []
        lastRecordingResult = nil
        startMetering()
    }

    /// 녹음을 멈추고 방금 만든 파일의 id/길이를 반환한다. 호출부가 이 값으로
    /// `SoundAssetRepository.createRecordedAsset`을 호출해 메타데이터를 저장하거나,
    /// 사용자가 취소하면 `RecordedSoundFileStore.deleteFile(for:)`로 지운다. 같은 결과를
    /// `lastRecordingResult`로도 남겨서, 최대 길이 도달로 자동 정지됐을 때도 화면이
    /// 반응형으로(버튼을 다시 누르지 않아도) 알아챌 수 있게 한다.
    @discardableResult
    func stopRecording() -> (id: UUID, durationMs: Int)? {
        guard let recorder, let pendingID else { return nil }
        meterTimer?.invalidate()
        meterTimer = nil
        let durationMs = Int(recorder.currentTime * 1000)
        recorder.stop()
        self.recorder = nil
        self.pendingID = nil
        isRecording = false
        let result = (id: pendingID, durationMs: durationMs)
        lastRecordingResult = result
        return result
    }

    /// 짧은 주기로 음량 레벨을 읽어 `levelSamples`에 쌓고, 경과 시간이 최대 길이에
    /// 도달하면 자동으로 정지한다.
    private func startMetering() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let recorder else { return }
        recorder.updateMeters()
        elapsedTime = recorder.currentTime
        levelSamples.append(normalizedLevel(from: recorder.averagePower(forChannel: 0)))

        if elapsedTime >= Self.maxDuration {
            stopRecording()
        }
    }

    /// dB(대략 -160...0, 무음에 가까울수록 더 낮음)를 파형 표시용 0...1로 정규화한다.
    /// `minDecibels` 이하는 무음으로 취급해 0으로 깐다.
    private func normalizedLevel(from decibels: Float) -> Float {
        let minDecibels: Float = -50
        guard decibels.isFinite, decibels > minDecibels else { return 0 }
        return (decibels - minDecibels) / -minDecibels
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

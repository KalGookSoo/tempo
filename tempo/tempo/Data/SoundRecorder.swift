//
//  SoundRecorder.swift
//  tempo
//

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
/// 오디오 하드웨어를 다룬다.
@Observable
final class SoundRecorder {
    private(set) var isRecording = false
    private(set) var permissionStatus: MicrophonePermissionStatus = .undetermined

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var pendingID: UUID?

    init() {
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
    /// `SoundAssetRepository.createRecordedAsset`을 호출해 메타데이터를 저장한다.
    func stopRecording() -> (id: UUID, durationMs: Int)? {
        guard let recorder, let pendingID else { return nil }
        let durationMs = Int(recorder.currentTime * 1000)
        recorder.stop()
        self.recorder = nil
        self.pendingID = nil
        isRecording = false
        return (pendingID, durationMs)
    }

    /// 녹음을 미리듣기한다.
    func preview(_ asset: SoundAsset) {
        guard let url = try? RecordedSoundFileStore.fileURL(for: asset.id) else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}

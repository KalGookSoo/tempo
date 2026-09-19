import AVFoundation
import Foundation

/// 녹음한 알림 큐 사운드를 잠금 화면 로컬 알림에서도 재생할 수 있게 변환/캐시한다.
/// iOS 로컬 알림의 커스텀 사운드는 앱 번들이나 앱 컨테이너의 `Library/Sounds`에 있는
/// `.caf`/`.aiff`/`.wav`만 쓸 수 있고 `.m4a`(녹음 형식)는 지원하지 않는다 — 그래서
/// 최초 사용 시 한 번 `.caf`로 변환해 그 폴더에 저장해두고, 이후에는 변환된 파일을
/// 그대로 재사용한다. 이슈 #113 참고.
enum NotificationSoundFileStore {
    enum StoreError: Error {
        case librarySoundsDirectoryUnavailable
    }

    /// `id`로 식별되는 녹음의 변환된 `.caf` 파일명(확장자 포함)을 반환한다.
    /// `UNNotificationSound(named:)`에 그대로 넘길 수 있다. 이미 변환해뒀으면 그
    /// 파일을 그대로 쓰고, 없으면 이번에 변환해서 만든다.
    static func cachedCAFFileName(for id: UUID) throws -> String {
        let fileName = "cue_\(id.uuidString).caf"
        let destinationURL = try librarySoundsURL().appendingPathComponent(fileName)

        guard !FileManager.default.fileExists(atPath: destinationURL.path) else {
            return fileName
        }

        let sourceURL = try RecordedSoundFileStore.fileURL(for: id)
        try convert(sourceURL: sourceURL, destinationURL: destinationURL)
        return fileName
    }

    private static func librarySoundsURL() throws -> URL {
        guard let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            throw StoreError.librarySoundsDirectoryUnavailable
        }
        let url = library.appendingPathComponent("Sounds", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// `.m4a`(AAC) 녹음 파일을 읽어 리니어 PCM `.caf` 파일로 다시 쓴다. `AVAudioFile`이
    /// 읽을 때 알아서 디코딩해주므로, 디코딩된 버퍼를 그대로 새 파일에 담기만 하면 된다.
    private static func convert(sourceURL: URL, destinationURL: URL) throws {
        let sourceFile = try AVAudioFile(forReading: sourceURL)
        let format = sourceFile.processingFormat
        let destinationSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]
        let destinationFile = try AVAudioFile(
            forWriting: destinationURL,
            settings: destinationSettings,
            commonFormat: .pcmFormatInt16,
            interleaved: true
        )

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096) else { return }
        while sourceFile.framePosition < sourceFile.length {
            try sourceFile.read(into: buffer)
            try destinationFile.write(from: buffer)
        }
    }
}

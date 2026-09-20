import AVFoundation
import Foundation
@testable import tempo
import Testing

/// 이슈 #113: 녹음(.m4a)을 로컬 알림이 지원하는 `.caf`로 변환해 앱 컨테이너의
/// `Library/Sounds`에 캐시해두는 로직을 검증한다. `SoundRecorder`와 같은 설정(AAC,
/// 44.1kHz, 모노)으로 짧은 무음 톤을 합성해 테스트용 원본 파일을 만든다.
@Suite("NotificationSoundFileStore")
struct NotificationSoundFileStoreTests {
    private func makeTestRecording(id: UUID) throws {
        let url = try RecordedSoundFileStore.fileURL(for: id)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
        ]
        let file = try AVAudioFile(forWriting: url, settings: settings)
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 4410))
        buffer.frameLength = buffer.frameCapacity
        try file.write(from: buffer)
    }

    private func cafURL(for fileName: String) throws -> URL {
        let library = try #require(FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first)
        return library.appendingPathComponent("Sounds").appendingPathComponent(fileName)
    }

    @Test("녹음 파일을 .caf로 변환해서 재생 가능한 파일을 만든다")
    func convertsRecordingToPlayableCAF() throws {
        let id = UUID()
        try makeTestRecording(id: id)
        defer { RecordedSoundFileStore.deleteFile(for: id) }

        let fileName = try NotificationSoundFileStore.cachedCAFFileName(for: id)
        defer { try? FileManager.default.removeItem(at: try cafURL(for: fileName)) }

        #expect(fileName == "cue_\(id.uuidString).caf")

        let converted = try AVAudioFile(forReading: cafURL(for: fileName))
        #expect(converted.length > 0)
    }

    @Test("이미 변환된 파일이 있으면 원본 없이도 그대로 재사용한다")
    func reusesExistingConversionWithoutSource() throws {
        let id = UUID()
        try makeTestRecording(id: id)

        let first = try NotificationSoundFileStore.cachedCAFFileName(for: id)
        defer { try? FileManager.default.removeItem(at: try cafURL(for: first)) }

        // 변환은 이미 끝났으니, 원본이 지워진 뒤에도 두 번째 호출은 원본을 다시
        // 읽으려 하지 않고 캐시된 파일을 그대로 반환해야 한다.
        RecordedSoundFileStore.deleteFile(for: id)
        let second = try NotificationSoundFileStore.cachedCAFFileName(for: id)

        #expect(first == second)
    }
}

//
//  RecordedSoundFileStoreTests.swift
//  tempoTests
//

import Foundation
@testable import tempo
import Testing

/// docs/testing-strategy.md 7번 항목: 녹음 파일 경로가 `SoundAsset.id` 기반으로 생성되고,
/// 사용자가 입력한 이름을 파일명으로 쓰지 않는지 검증한다.
@Suite("RecordedSoundFileStore")
struct RecordedSoundFileStoreTests {
    @Test("relativePath는 sounds/recorded/ 아래 id 기반 파일명을 만든다")
    func relativePathIsIDBased() {
        let id = UUID()

        let path = RecordedSoundFileStore.relativePath(for: id)

        #expect(path == "sounds/recorded/sound_\(id.uuidString).m4a")
    }

    @Test("서로 다른 id는 서로 다른 경로를 만든다")
    func differentIDsProduceDifferentPaths() {
        let first = RecordedSoundFileStore.relativePath(for: UUID())
        let second = RecordedSoundFileStore.relativePath(for: UUID())

        #expect(first != second)
    }

    @Test("fileURL은 문서 디렉터리 기준 relativePath와 일치하는 절대 경로를 반환한다")
    func fileURLMatchesRelativePath() throws {
        let id = UUID()

        let url = try RecordedSoundFileStore.fileURL(for: id)

        #expect(url.path.hasSuffix(RecordedSoundFileStore.relativePath(for: id)))
    }
}

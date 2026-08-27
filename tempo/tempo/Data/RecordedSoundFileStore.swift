//
//  RecordedSoundFileStore.swift
//  tempo
//

import Foundation

/// 녹음 파일의 저장 경로 규칙을 결정한다. `SoundAsset.id` 기반 파일명만 쓰고, 사용자가
/// 입력한 표시 이름은 파일명에 반영하지 않는다. docs/local-persistence-strategy.md
/// "파일 저장 전략" 참고.
enum RecordedSoundFileStore {
    enum RecordedSoundFileStoreError: Error {
        case documentsDirectoryUnavailable
    }

    /// 문서 디렉터리 기준 상대 경로. `SoundAsset.relativePath`에 그대로 저장한다.
    static func relativePath(for id: UUID) -> String {
        "sounds/recorded/sound_\(id.uuidString).m4a"
    }

    /// 녹음을 읽고 쓸 절대 URL. 상위 디렉터리가 없으면 만든다.
    static func fileURL(for id: UUID) throws -> URL {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw RecordedSoundFileStoreError.documentsDirectoryUnavailable
        }
        let url = documents.appendingPathComponent(relativePath(for: id))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        return url
    }

    /// 파일 삭제를 시도한다. `local-persistence-strategy.md`의 "실제 파일 삭제 실패 가능성을
    /// 별도 처리" 원칙에 따라, 실패해도 에러를 던지지 않는다.
    static func deleteFile(for id: UUID) {
        guard let url = try? fileURL(for: id) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

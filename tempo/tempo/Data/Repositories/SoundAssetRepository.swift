import Foundation
import SwiftData

enum SoundAssetRepositoryError: Error {
    case cannotModifyNonRecordedAsset
}

/// 사용자가 직접 녹음한 `SoundAsset(kind: .recorded)`에 대한 조회/생성/이름변경/삭제를
/// 담당한다. 화면은 SwiftData `ModelContext`를 직접 다루지 않고 이 계층을 통해 접근한다.
/// docs/local-persistence-strategy.md "데이터 접근 계층" 참고.
final class SoundAssetRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 삭제되지 않은 녹음을 최신순으로 조회한다.
    func findRecordedAssets() throws -> [SoundAsset] {
        let descriptor = FetchDescriptor<SoundAsset>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).filter { $0.kind == .recorded && $0.deletedAt == nil }
    }

    /// 녹음을 마친 뒤 메타데이터를 저장한다. `id`는 파일명에 쓰인 것과 같은 값을 넘겨받는다
    /// (`RecordedSoundFileStore.relativePath(for:)` 참고). `waveformSamples`는 녹음 중
    /// 수집한 음량 레벨(0...1)로, 목록 화면이 파형을 다시 계산하지 않고 그대로 그릴 수
    /// 있도록 함께 저장한다(이슈 #64).
    @discardableResult
    func createRecordedAsset(id: UUID, name: String, durationMs: Int?, waveformSamples: [Float] = []) throws -> SoundAsset {
        let asset = SoundAsset(
            id: id,
            kind: .recorded,
            name: name,
            relativePath: RecordedSoundFileStore.relativePath(for: id),
            durationMs: durationMs,
            createdAt: Date(),
            waveformSamples: waveformSamples
        )
        modelContext.insert(asset)
        try modelContext.save()
        return asset
    }

    /// 녹음의 표시 이름만 바꾼다. 파일명 자체는 바뀌지 않는다.
    func rename(_ asset: SoundAsset, to name: String) throws {
        guard asset.kind == .recorded else {
            throw SoundAssetRepositoryError.cannotModifyNonRecordedAsset
        }
        asset.name = name
        try modelContext.save()
    }

    /// `asset`을 참조 중인 `CueProfile`을 모두 찾는다(사용 중인 녹음을 삭제하기 전 확인할 때 사용된다).
    func profilesReferencing(_ asset: SoundAsset) throws -> [CueProfile] {
        let profiles = try modelContext.fetch(FetchDescriptor<CueProfile>())
        return profiles.filter { profile in
            CueConfig.allEventKeyPaths.contains { keyPath in
                profile.config[keyPath: keyPath].soundAssetID == asset.id
            }
        }
    }

    /// `asset`을 참조하는 모든 이벤트의 `soundAssetID`만 `nil`로 되돌린다(`mode`는 그대로
    /// 유지 — 사운드만 기본값으로 돌아간다). 삭제 직전에 호출해 죽은 참조가 남지 않게 한다.
    func clearReferences(to asset: SoundAsset, in profiles: [CueProfile]) throws {
        for profile in profiles {
            for keyPath in CueConfig.allEventKeyPaths {
                if profile.config[keyPath: keyPath].soundAssetID == asset.id {
                    profile.config[keyPath: keyPath].soundAssetID = nil
                }
            }
        }
        try modelContext.save()
    }

    /// soft delete하고, 실제 파일 삭제도 시도한다(실패해도 앱이 죽지 않는다).
    func delete(_ asset: SoundAsset) throws {
        guard asset.kind == .recorded else {
            throw SoundAssetRepositoryError.cannotModifyNonRecordedAsset
        }
        asset.deletedAt = Date()
        try modelContext.save()
        RecordedSoundFileStore.deleteFile(for: asset.id)
    }
}

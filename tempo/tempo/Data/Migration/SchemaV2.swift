import Foundation
import SwiftData

/// `AppSettings.hasCompletedOnboarding` 필드 추가. 기존 필드에 기본값이 있는 단순 추가라
/// lightweight 마이그레이션으로 처리한다. docs/local-persistence-strategy.md
/// "마이그레이션 원칙" 참고.
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TimerPreset.self, CueProfile.self, SoundAsset.self, AppSettings.self]
    }

    /// v2 시점 `SoundAsset`의 형태 스냅샷(`waveformSamples` 없음) — SchemaV1과 동일한
    /// 이유로, SchemaV3에서 필드가 추가되기 전 형태를 그대로 얼려둔다.
    @Model
    final class SoundAsset {
        @Attribute(.unique) var id: UUID
        var kind: SoundAssetKind
        var name: String
        var relativePath: String?
        var durationMs: Int?
        var createdAt: Date
        var deletedAt: Date?

        init(
            id: UUID = UUID(),
            kind: SoundAssetKind,
            name: String,
            relativePath: String? = nil,
            durationMs: Int? = nil,
            createdAt: Date,
            deletedAt: Date? = nil
        ) {
            self.id = id
            self.kind = kind
            self.name = name
            self.relativePath = relativePath
            self.durationMs = durationMs
            self.createdAt = createdAt
            self.deletedAt = deletedAt
        }
    }
}

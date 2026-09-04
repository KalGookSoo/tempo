import Foundation
import SwiftData

/// 기본 사운드, 사용자 음원, 직접 녹음 음성 큐를 관리한다. 바이너리 파일 자체는 FileManager에
/// 저장하고, 여기에는 경로/메타데이터만 둔다. docs/local-persistence-strategy.md
/// "SoundAsset" 참고.
@Model
final class SoundAsset {
    @Attribute(.unique) var id: UUID
    var kind: SoundAssetKind
    var name: String
    var relativePath: String? // 파일 시스템 경로(문서 디렉터리 기준) 또는 앱 asset 이름
    var durationMs: Int?
    var createdAt: Date
    var deletedAt: Date? // soft delete
    /// 녹음 중 수집한 음량 레벨(0...1) 샘플. 목록 화면에서 파형을 다시 계산하지 않고
    /// 그대로 그릴 수 있도록 녹음 시점에 함께 저장한다. 빌트인/가져온 사운드는 빈
    /// 배열이다. 이슈 #64 참고.
    var waveformSamples: [Float] = []

    init(
        id: UUID = UUID(),
        kind: SoundAssetKind,
        name: String,
        relativePath: String? = nil,
        durationMs: Int? = nil,
        createdAt: Date,
        deletedAt: Date? = nil,
        waveformSamples: [Float] = []
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.relativePath = relativePath
        self.durationMs = durationMs
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.waveformSamples = waveformSamples
    }
}

enum SoundAssetKind: String, Codable {
    case builtin
    case imported
    case recorded
}

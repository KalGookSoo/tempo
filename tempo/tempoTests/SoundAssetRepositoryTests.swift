//
//  SoundAssetRepositoryTests.swift
//  tempoTests
//

import Foundation
import SwiftData
@testable import tempo
import Testing

/// docs/testing-strategy.md 6번 항목: 녹음 사운드(`SoundAsset kind == .recorded`)에 대한
/// SwiftData 통합 테스트. 이슈 #8 참고.
@Suite("SoundAssetRepository")
@MainActor
struct SoundAssetRepositoryTests {
    private func makeInMemoryStore() throws -> (container: ModelContainer, context: ModelContext) {
        let container = try ModelContainer(
            for: Schema(versionedSchema: SchemaV1.self),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return (container, container.mainContext)
    }

    @Test("녹음을 생성하면 recorded로 저장되고 id 기반 relativePath를 갖는다")
    func createsRecordedAsset() throws {
        let store = try makeInMemoryStore()
        let repository = SoundAssetRepository(modelContext: store.context)
        let id = UUID()

        let asset = try repository.createRecordedAsset(id: id, name: "녹음 1", durationMs: 1500)

        #expect(asset.kind == .recorded)
        #expect(asset.relativePath == "sounds/recorded/sound_\(id.uuidString).m4a")
        #expect(asset.durationMs == 1500)
    }

    @Test("빌트인 사운드가 섞여있어도 녹음 목록만 조회된다")
    func findsOnlyRecordedAssets() throws {
        let store = try makeInMemoryStore()
        try SoundAssetSeeder.seedDefaultsIfNeeded(in: store.context)
        let repository = SoundAssetRepository(modelContext: store.context)
        try repository.createRecordedAsset(id: UUID(), name: "녹음 1", durationMs: 1000)

        let recordings = try repository.findRecordedAssets()

        #expect(recordings.count == 1)
        #expect(recordings.allSatisfy { $0.kind == .recorded })
    }

    @Test("녹음 이름을 바꿀 수 있고 파일명(relativePath)은 그대로 유지된다")
    func renamesRecordedAsset() throws {
        let store = try makeInMemoryStore()
        let repository = SoundAssetRepository(modelContext: store.context)
        let asset = try repository.createRecordedAsset(id: UUID(), name: "녹음 1", durationMs: nil)
        let originalPath = asset.relativePath

        try repository.rename(asset, to: "스쿼트 시작음")

        #expect(asset.name == "스쿼트 시작음")
        #expect(asset.relativePath == originalPath)
    }

    @Test("soft delete된 녹음은 목록 조회에서 제외된다")
    func softDeletedRecordingIsExcludedFromList() throws {
        let store = try makeInMemoryStore()
        let repository = SoundAssetRepository(modelContext: store.context)
        let asset = try repository.createRecordedAsset(id: UUID(), name: "녹음 1", durationMs: nil)

        try repository.delete(asset)

        #expect(try repository.findRecordedAssets().isEmpty)
        #expect(asset.deletedAt != nil)
    }

    @Test("빌트인 사운드는 이름을 바꾸거나 삭제할 수 없다")
    func cannotModifyBuiltinAsset() throws {
        let store = try makeInMemoryStore()
        try SoundAssetSeeder.seedDefaultsIfNeeded(in: store.context)
        let repository = SoundAssetRepository(modelContext: store.context)
        let builtin = try #require(try store.context.fetch(FetchDescriptor<SoundAsset>()).first { $0.kind == .builtin })

        #expect(throws: SoundAssetRepositoryError.self) {
            try repository.rename(builtin, to: "바꿔치기")
        }
        #expect(throws: SoundAssetRepositoryError.self) {
            try repository.delete(builtin)
        }
    }
}

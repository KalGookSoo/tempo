//
//  SoundAssetSeederTests.swift
//  tempoTests
//

import Foundation
import SwiftData
@testable import tempo
import Testing

/// docs/testing-strategy.md 6번 항목과 같은 성격의 SwiftData 통합 테스트: 앱 최초 실행 시
/// 기본 사운드 4종이 seed되는지, 두 번 실행해도 중복되지 않는지 검증한다. 이벤트별 기본
/// 사운드 이름 매핑(`defaultSoundName(for:)`)은 순수 함수라 별도로 검증한다.
@Suite("SoundAssetSeeder")
@MainActor
struct SoundAssetSeederTests {
    private func makeInMemoryStore() throws -> (container: ModelContainer, context: ModelContext) {
        let container = try ModelContainer(
            for: Schema(versionedSchema: SchemaV1.self),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return (container, container.mainContext)
    }

    @Test("최초 실행 시 기본 사운드 4종이 builtin으로 seed된다")
    func seedsThreeBuiltinSounds() throws {
        let store = try makeInMemoryStore()
        try SoundAssetSeeder.seedDefaultsIfNeeded(in: store.context)

        let assets = try store.context.fetch(FetchDescriptor<SoundAsset>())

        #expect(assets.count == 4)
        #expect(Set(assets.map(\.name)) == ["짧은 비프", "긴 비프", "종료음", "긴 비프 (3초)"])
        #expect(assets.allSatisfy { $0.kind == .builtin })
        #expect(assets.allSatisfy { $0.relativePath != nil })
    }

    @Test("같은 컨텍스트에서 두 번 실행해도 중복 생성되지 않는다")
    func seedingTwiceDoesNotDuplicate() throws {
        let store = try makeInMemoryStore()
        try SoundAssetSeeder.seedDefaultsIfNeeded(in: store.context)
        try SoundAssetSeeder.seedDefaultsIfNeeded(in: store.context)

        let assets = try store.context.fetch(FetchDescriptor<SoundAsset>())
        #expect(assets.count == 4)
    }

    @Test("일부 기본 사운드만 이미 있으면 없는 것만 채워 넣는다")
    func seedsOnlyMissingSounds() throws {
        let store = try makeInMemoryStore()
        // 앱 업데이트 전에 기본 사운드 3종만 시드된 기존 설치를 흉내낸다.
        let now = Date()
        store.context.insert(SoundAsset(kind: .builtin, name: "짧은 비프", relativePath: "beep.wav", createdAt: now))
        store.context.insert(SoundAsset(kind: .builtin, name: "긴 비프", relativePath: "beep-long.wav", createdAt: now))
        store.context.insert(SoundAsset(kind: .builtin, name: "종료음", relativePath: "finish.wav", createdAt: now))
        try store.context.save()

        try SoundAssetSeeder.seedDefaultsIfNeeded(in: store.context)

        let assets = try store.context.fetch(FetchDescriptor<SoundAsset>())
        #expect(assets.count == 4)
        #expect(Set(assets.map(\.name)) == ["짧은 비프", "긴 비프", "종료음", "긴 비프 (3초)"])
    }

    @Test("전체 종료 이벤트의 기본 사운드는 긴 비프(3초)이고, 나머지는 짧은 비프다")
    func defaultSoundNameMapsFinishToFinishSound() {
        #expect(SoundAssetSeeder.defaultSoundName(for: .finish) == "긴 비프 (3초)")
        #expect(SoundAssetSeeder.defaultSoundName(for: .prepareStart) == "짧은 비프")
        #expect(SoundAssetSeeder.defaultSoundName(for: .workStart) == "짧은 비프")
        #expect(SoundAssetSeeder.defaultSoundName(for: .restStart) == "짧은 비프")
        #expect(SoundAssetSeeder.defaultSoundName(for: .segmentEnd) == "짧은 비프")
        #expect(SoundAssetSeeder.defaultSoundName(for: .roundEnd) == "짧은 비프")
        #expect(SoundAssetSeeder.defaultSoundName(for: .finalRoundEnter) == "짧은 비프")
        #expect(SoundAssetSeeder.defaultSoundName(for: .countdownLead(secondsRemaining: 3)) == "짧은 비프")
    }
}

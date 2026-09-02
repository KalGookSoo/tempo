import SwiftData
@testable import tempo
import Testing

/// docs/testing-strategy.md 2, 6번 항목: 기본 프리셋 값 회귀 + SwiftData 통합 테스트.
/// `ModelContainer.mainContext`가 MainActor 격리라 스위트 전체를 MainActor에서 실행한다.
@Suite("PresetRepository")
@MainActor
struct PresetRepositoryTests {
    /// in-memory store는 `ModelContainer`가 살아있는 동안만 유효하다. `context`만 반환하고
    /// `container`를 버리면 함수가 끝나는 즉시 컨테이너가 해제되어 이후 `context` 사용 시
    /// 크래시한다 — 그래서 둘 다 묶어서 반환하고 호출부에서 함께 들고 있는다.
    private func makeInMemoryStore() throws -> (container: ModelContainer, context: ModelContext) {
        let container = try ModelContainer(
            for: Schema(versionedSchema: SchemaV1.self),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return (container, container.mainContext)
    }

    @Test("최초 실행 시 기본 프리셋 3개가 seed된다")
    func seedsDefaultPresets() throws {
        let store = try makeInMemoryStore()
        try PresetSeeder.seedDefaultsIfNeeded(in: store.context)

        let presets = try PresetRepository(modelContext: store.context).findIntervalPresets()

        #expect(presets.count == 3)
        #expect(Set(presets.map(\.name)) == ["Tabata", "FGB 3R", "EMOM"])
        #expect(presets.allSatisfy { $0.kind == .default })
    }

    @Test("같은 컨텍스트에서 seed를 두 번 실행해도 중복 생성되지 않는다")
    func seedingTwiceDoesNotDuplicate() throws {
        let store = try makeInMemoryStore()
        try PresetSeeder.seedDefaultsIfNeeded(in: store.context)
        try PresetSeeder.seedDefaultsIfNeeded(in: store.context)

        let presets = try PresetRepository(modelContext: store.context).findIntervalPresets()
        #expect(presets.count == 3)
    }

    @Test("기본 프리셋 수치가 명세와 정확히 일치한다")
    func defaultPresetValuesMatchSpec() throws {
        let store = try makeInMemoryStore()
        try PresetSeeder.seedDefaultsIfNeeded(in: store.context)
        let presets = try PresetRepository(modelContext: store.context).findIntervalPresets()

        let tabata = try #require(presets.first { $0.name == "Tabata" })
        #expect(tabata.config.rounds == 8)
        #expect(tabata.config.segments == [
            IntervalSegment(type: .work, seconds: 20),
            IntervalSegment(type: .rest, seconds: 10),
        ])

        let fgb3 = try #require(presets.first { $0.name == "FGB 3R" })
        #expect(fgb3.config.rounds == 3)
        #expect(fgb3.config.segments == [
            IntervalSegment(type: .work, seconds: 300),
            IntervalSegment(type: .rest, seconds: 60),
        ])

        let emom = try #require(presets.first { $0.name == "EMOM" })
        #expect(emom.config.segments.contains(IntervalSegment(type: .rest, seconds: 0)))
    }

    @Test("기본 프리셋을 복제하면 원본은 그대로 유지된다")
    func duplicatingDefaultPresetKeepsOriginalUnchanged() throws {
        let store = try makeInMemoryStore()
        try PresetSeeder.seedDefaultsIfNeeded(in: store.context)
        let repository = PresetRepository(modelContext: store.context)
        let tabata = try #require(try repository.findIntervalPresets().first { $0.name == "Tabata" })

        let copy = try repository.duplicate(tabata, name: "내 타바타")

        #expect(copy.kind == .custom)
        #expect(copy.config == tabata.config)
        #expect(tabata.kind == .default)
        #expect(tabata.name == "Tabata")
    }

    @Test("기본 프리셋도 수정할 수 있다")
    func updatingDefaultPresetSucceeds() throws {
        let store = try makeInMemoryStore()
        try PresetSeeder.seedDefaultsIfNeeded(in: store.context)
        let repository = PresetRepository(modelContext: store.context)
        let tabata = try #require(try repository.findIntervalPresets().first { $0.name == "Tabata" })

        try repository.update(tabata, name: "내 타바타")

        let updated = try #require(try repository.findIntervalPresets().first { $0.id == tabata.id })
        #expect(updated.name == "내 타바타")
    }

    @Test("기본 프리셋도 삭제할 수 있다")
    func deletingDefaultPresetSucceeds() throws {
        let store = try makeInMemoryStore()
        try PresetSeeder.seedDefaultsIfNeeded(in: store.context)
        let repository = PresetRepository(modelContext: store.context)
        let tabata = try #require(try repository.findIntervalPresets().first { $0.name == "Tabata" })

        try repository.delete(tabata)

        #expect(try repository.findIntervalPresets().first { $0.id == tabata.id } == nil)
        #expect(tabata.deletedAt != nil)
    }

    @Test("삭제된 기본 프리셋은 재시드해도 되살아나지 않는다")
    func deletedDefaultPresetIsNotReseeded() throws {
        let store = try makeInMemoryStore()
        try PresetSeeder.seedDefaultsIfNeeded(in: store.context)
        let repository = PresetRepository(modelContext: store.context)
        let tabata = try #require(try repository.findIntervalPresets().first { $0.name == "Tabata" })

        try repository.delete(tabata)
        try PresetSeeder.seedDefaultsIfNeeded(in: store.context)

        #expect(try repository.findIntervalPresets().first { $0.name == "Tabata" } == nil)
    }

    @Test("커스텀 프리셋을 생성, 수정, 삭제할 수 있다")
    func customPresetCRUD() throws {
        let store = try makeInMemoryStore()
        try PresetSeeder.seedDefaultsIfNeeded(in: store.context)
        let repository = PresetRepository(modelContext: store.context)

        let created = try repository.createCustomPreset(
            name: "복싱 3분 1분",
            config: IntervalConfig(
                rounds: 4,
                prepareSeconds: 10,
                segments: [
                    IntervalSegment(type: .work, seconds: 180),
                    IntervalSegment(type: .rest, seconds: 60),
                ]
            )
        )
        #expect(created.kind == .custom)

        try repository.update(created, name: "복싱 3라운드")
        let updated = try #require(try repository.findIntervalPresets().first { $0.id == created.id })
        #expect(updated.name == "복싱 3라운드")

        try repository.delete(created)
        #expect(try repository.findIntervalPresets().first { $0.id == created.id } == nil)
    }

    @Test("soft delete된 커스텀 프리셋은 목록 조회에서 제외된다")
    func softDeletedCustomPresetIsExcludedFromList() throws {
        let store = try makeInMemoryStore()
        try PresetSeeder.seedDefaultsIfNeeded(in: store.context)
        let repository = PresetRepository(modelContext: store.context)

        let custom = try repository.createCustomPreset(
            name: "월요일 와드",
            config: IntervalConfig(
                rounds: 4,
                prepareSeconds: 10,
                segments: [
                    IntervalSegment(type: .work, seconds: 180),
                    IntervalSegment(type: .rest, seconds: 60),
                ]
            )
        )
        #expect(try repository.findIntervalPresets().count == 4)

        try repository.delete(custom)

        #expect(try repository.findIntervalPresets().count == 3)
        #expect(custom.deletedAt != nil)
    }
}

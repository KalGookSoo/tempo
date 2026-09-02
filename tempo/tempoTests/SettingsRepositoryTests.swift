import Foundation
import SwiftData
@testable import tempo
import Testing

/// docs/testing-strategy.md 6번 항목과 같은 성격의 SwiftData 통합 테스트: `AppSettings`
/// row가 하나만 생성되는지, 온보딩 완료 표시가 저장되는지 검증한다. 이슈 #9 참고.
@Suite("SettingsRepository")
@MainActor
struct SettingsRepositoryTests {
    private func makeInMemoryStore() throws -> (container: ModelContainer, context: ModelContext) {
        let container = try ModelContainer(
            for: Schema(versionedSchema: SchemaV2.self),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return (container, container.mainContext)
    }

    @Test("AppSettings row가 없으면 기본값으로 하나 생성한다")
    func seedsDefaultSettings() throws {
        let store = try makeInMemoryStore()
        let repository = SettingsRepository(modelContext: store.context)

        let settings = try repository.seedDefaultIfNeeded()

        #expect(settings.hasCompletedOnboarding == false)
        #expect(try store.context.fetch(FetchDescriptor<AppSettings>()).count == 1)
    }

    @Test("두 번 seed해도 row가 중복 생성되지 않는다")
    func seedingTwiceDoesNotDuplicate() throws {
        let store = try makeInMemoryStore()
        let repository = SettingsRepository(modelContext: store.context)

        try repository.seedDefaultIfNeeded()
        try repository.seedDefaultIfNeeded()

        #expect(try store.context.fetch(FetchDescriptor<AppSettings>()).count == 1)
    }

    @Test("온보딩을 완료하면 hasCompletedOnboarding이 true로 저장된다")
    func completingOnboardingPersists() throws {
        let store = try makeInMemoryStore()
        let repository = SettingsRepository(modelContext: store.context)
        try repository.seedDefaultIfNeeded()

        try repository.completeOnboarding()

        let settings = try #require(try repository.find())
        #expect(settings.hasCompletedOnboarding == true)
    }
}

import Foundation
import SwiftData

/// `AppSettings`(앱 인스턴스당 row 하나)에 대한 조회/생성/수정을 담당한다.
/// docs/local-persistence-strategy.md "데이터 접근 계층", "AppSettings" 참고.
final class SettingsRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// `AppSettings` row가 없으면 기본값으로 만든다. 이미 있으면 그대로 반환한다.
    @discardableResult
    func seedDefaultIfNeeded() throws -> AppSettings {
        if let existing = try find() {
            return existing
        }
        let settings = AppSettings(updatedAt: Date())
        modelContext.insert(settings)
        try modelContext.save()
        return settings
    }

    func find() throws -> AppSettings? {
        try modelContext.fetch(FetchDescriptor<AppSettings>()).first
    }

    /// 온보딩을 완료(또는 건너뛰기)했다고 표시한다. 이후 재실행 시 다시 표시되지 않는다.
    func completeOnboarding() throws {
        guard let settings = try find() else { return }
        settings.hasCompletedOnboarding = true
        settings.updatedAt = Date()
        try modelContext.save()
    }
}

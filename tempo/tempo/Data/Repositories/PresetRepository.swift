//
//  PresetRepository.swift
//  tempo
//

import Foundation
import SwiftData

enum PresetRepositoryError: Error {
    case cannotModifyDefaultPreset
}

/// `TimerPreset`에 대한 조회/생성/수정/삭제를 담당한다. 화면은 SwiftData `ModelContext`를
/// 직접 다루지 않고 이 계층을 통해 접근한다. docs/local-persistence-strategy.md
/// "데이터 접근 계층" 참고.
final class PresetRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 삭제되지 않은 프리셋을 정렬 순서대로 조회한다.
    func findIntervalPresets() throws -> [TimerPreset] {
        let descriptor = FetchDescriptor<TimerPreset>(
            predicate: #Predicate { $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// id로 삭제되지 않은 프리셋 하나를 조회한다. 인터벌 실행 화면이 `programID`로 실제
    /// 설정을 가져올 때 쓴다.
    func findPreset(id: UUID) throws -> TimerPreset? {
        try findIntervalPresets().first { $0.id == id }
    }

    @discardableResult
    func createCustomPreset(
        name: String,
        config: IntervalConfig,
        cueProfileID: UUID? = nil
    ) throws -> TimerPreset {
        let now = Date()
        let preset = try TimerPreset(
            kind: .custom,
            name: name,
            config: config,
            cueProfileID: cueProfileID,
            sortOrder: nextSortOrder(),
            createdAt: now,
            updatedAt: now
        )
        modelContext.insert(preset)
        try modelContext.save()
        return preset
    }

    /// 기본 프리셋을 복제해 사용자 프리셋으로 만든다. 원본은 변경하지 않는다.
    @discardableResult
    func duplicate(_ preset: TimerPreset, name: String? = nil) throws -> TimerPreset {
        try createCustomPreset(
            name: name ?? "\(preset.name) 사본",
            config: preset.config,
            cueProfileID: preset.cueProfileID
        )
    }

    /// 사용자 프리셋만 수정할 수 있다. 기본 프리셋을 바꾸고 싶으면 복제해서 custom으로 만든다.
    func update(_ preset: TimerPreset, name: String? = nil, config: IntervalConfig? = nil) throws {
        guard preset.kind == .custom else {
            throw PresetRepositoryError.cannotModifyDefaultPreset
        }
        if let name {
            preset.name = name
        }
        if let config {
            preset.config = config
        }
        preset.updatedAt = Date()
        try modelContext.save()
    }

    /// soft delete. 기본 프리셋은 삭제할 수 없다.
    func delete(_ preset: TimerPreset) throws {
        guard preset.kind == .custom else {
            throw PresetRepositoryError.cannotModifyDefaultPreset
        }
        preset.deletedAt = Date()
        try modelContext.save()
    }

    private func nextSortOrder() throws -> Int {
        let all = try modelContext.fetch(FetchDescriptor<TimerPreset>())
        return (all.map(\.sortOrder).max() ?? -1) + 1
    }
}

//
//  PresetSeeder.swift
//  tempo
//

import Foundation
import SwiftData

/// 앱 최초 실행 시 기본 프리셋을 삽입한다. docs/local-persistence-strategy.md
/// "기본 프리셋 seed 전략", docs/timer-functional-spec.md "인터벌 프리셋" 참고.
enum PresetSeeder {
    /// 기본 프리셋이 하나도 없으면 4개(tabata, fgb_5r, fgb_3r, emom)를 삽입한다.
    /// 이미 있으면 아무 것도 하지 않는다.
    static func seedDefaultsIfNeeded(in modelContext: ModelContext) throws {
        // #Predicate 매크로가 `PresetKind.default` 케이스 비교를 키 경로로 풀어내지 못해
        // 전체를 가져와 메모리에서 필터링한다. 기본 프리셋은 4개뿐이라 비용이 크지 않다.
        let existingDefaults = try modelContext.fetch(FetchDescriptor<TimerPreset>())
            .filter { $0.kind == .default }
        guard existingDefaults.isEmpty else { return }

        let now = Date()
        for (index, seed) in defaultSeeds.enumerated() {
            let preset = TimerPreset(
                kind: .default,
                name: seed.name,
                config: seed.config,
                sortOrder: index,
                createdAt: now,
                updatedAt: now
            )
            modelContext.insert(preset)
        }
        try modelContext.save()
    }

    /// 기본 제공 프리셋 4종. Tabata/FGB 5R/FGB 3R은 명세(docs/timer-functional-spec.md
    /// "기본 제공 프리셋")의 수치를 그대로 쓴다. EMOM은 명세상 "반복 시간: 사용자가 설정"이라
    /// 고정값이 없어, 같은 문서의 "EMOM 예시"(반복 시간 1분, 반복 횟수 10)를 기본값으로 쓴다 —
    /// 즉시 실행 가능해야 한다는 요구사항을 충족하면서도 사용자가 바로 복제·수정하기 쉬운 값이다.
    /// 모든 프리셋의 준비 카운트다운은 명세 기본값인 10초를 따른다.
    static let defaultSeeds: [(name: String, config: IntervalConfig)] = [
        (
            "Tabata",
            IntervalConfig(
                rounds: 8,
                prepareSeconds: 10,
                segments: [
                    IntervalSegment(type: .work, seconds: 20),
                    IntervalSegment(type: .rest, seconds: 10),
                ]
            )
        ),
        (
            "FGB 5R",
            IntervalConfig(
                rounds: 5,
                prepareSeconds: 10,
                segments: [
                    IntervalSegment(type: .work, seconds: 300),
                    IntervalSegment(type: .rest, seconds: 60),
                ]
            )
        ),
        (
            "FGB 3R",
            IntervalConfig(
                rounds: 3,
                prepareSeconds: 10,
                segments: [
                    IntervalSegment(type: .work, seconds: 300),
                    IntervalSegment(type: .rest, seconds: 60),
                ]
            )
        ),
        (
            "EMOM",
            IntervalConfig(
                rounds: 10,
                prepareSeconds: 10,
                segments: [
                    IntervalSegment(type: .work, seconds: 60),
                    IntervalSegment(type: .rest, seconds: 0),
                ]
            )
        ),
    ]
}

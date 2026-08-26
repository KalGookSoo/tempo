//
//  StopwatchEngine.swift
//  tempo
//

import Foundation
import Observation

/// 스톱워치 경과 시간/랩 계산을 담당하는 View 밖 순수 타입. `TimerEngine`과 마찬가지로
/// `Date`를 직접 주입받아 계산하므로 실제 시간 흐름 없이 테스트할 수 있다.
/// docs/use-cases/stopwatch.md, docs/timer-functional-spec.md "2. 스톱워치" 참고.
@Observable
final class StopwatchEngine {
    static let maxElapsed: TimeInterval = 99 * 60 + 59.99 // 99:59.99

    struct Lap: Identifiable, Equatable {
        /// 1부터 시작하는 랩 번호.
        let id: Int
        /// 직전 랩 이후 경과(첫 랩이면 시작 시점부터 경과).
        let lapDuration: TimeInterval
        /// 시작부터 이 랩까지의 누적 경과.
        let cumulativeDuration: TimeInterval
    }

    var state: TimerState
    private(set) var laps: [Lap]

    private var startedAt: Date?
    private var pausedElapsed: TimeInterval

    init() {
        state = .idle
        laps = []
        startedAt = nil
        pausedElapsed = 0
    }

    /// 현재 경과 시간(초). 최댓값에 도달하면 `state`를 `.completed`로 전이시키고 그 이후로는
    /// 더 흐르지 않는다.
    func elapsed(at now: Date) -> TimeInterval {
        let raw = startedAt.map { pausedElapsed + now.timeIntervalSince($0) } ?? pausedElapsed
        let clamped = min(raw, Self.maxElapsed)

        if clamped >= Self.maxElapsed, state == .running {
            state = .completed
            startedAt = nil
            pausedElapsed = Self.maxElapsed
        }

        return clamped
    }

    func start(at now: Date) {
        state = .running
        startedAt = now
    }

    func stop(at now: Date) {
        pausedElapsed = elapsed(at: now)
        startedAt = nil
        state = .paused
    }

    func resume(at now: Date) {
        state = .running
        startedAt = now
    }

    func reset() {
        state = .idle
        startedAt = nil
        pausedElapsed = 0
        laps = []
    }

    /// 지금까지의 경과 시간을 새 랩으로 기록한다.
    func recordLap(at now: Date) {
        let cumulative = elapsed(at: now)
        let previousCumulative = laps.last?.cumulativeDuration ?? 0
        let lap = Lap(
            id: laps.count + 1,
            lapDuration: cumulative - previousCumulative,
            cumulativeDuration: cumulative
        )
        laps.append(lap)
    }

    /// `MM:SS.CS` 문자열로 표시한다 (`CS` = 1/100초). View 밖에서 테스트할 수 있도록 순수 함수로 둔다.
    static func formattedClock(elapsed: TimeInterval) -> String {
        let totalCentiseconds = Int(elapsed * 100)
        let minutes = totalCentiseconds / 6000
        let seconds = (totalCentiseconds % 6000) / 100
        let centiseconds = totalCentiseconds % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
}

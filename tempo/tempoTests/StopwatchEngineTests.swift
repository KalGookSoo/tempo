import Foundation
@testable import tempo
import Testing

/// docs/testing-strategy.md 3번 항목(시간 표시 포맷팅)과 `StopwatchEngine`의 경과 시간/랩/
/// 최댓값 처리를 검증한다. `Date`를 직접 주입해서 검증하므로 실제로 기다릴 필요가 없다.
@Suite("StopwatchEngine")
struct StopwatchEngineTests {
    private let base = Date()

    /// `Date` 뺄셈은 큰 절대 시각(현재 시각)에서 작은 값을 더했다가 다시 빼는 연산이라
    /// 부동소수점 오차가 아주 미세하게 생길 수 있다. 그래서 `TimeInterval` 비교는 항상
    /// 약간의 허용 오차를 두고 비교한다 (0.001초 = 1/100초 표시 단위보다 훨씬 작음).
    private func isClose(_ a: TimeInterval, _ b: TimeInterval) -> Bool {
        abs(a - b) < 0.001
    }

    @Test("초기 상태는 idle이고 경과 시간은 0이다")
    func initialStateIsIdleWithZeroElapsed() {
        let engine = StopwatchEngine()
        #expect(engine.state == .idle)
        #expect(engine.elapsed(at: base) == 0)
    }

    @Test("시작 후 경과 시간이 흐른 시간만큼 증가한다")
    func elapsedIncreasesAfterStart() {
        let engine = StopwatchEngine()
        engine.start(at: base)

        #expect(isClose(engine.elapsed(at: base.addingTimeInterval(12.34)), 12.34))
        #expect(engine.state == .running)
    }

    @Test("정지하면 그 시점 경과 시간에서 멈춘다")
    func elapsedFreezesWhenStopped() {
        let engine = StopwatchEngine()
        engine.start(at: base)
        engine.stop(at: base.addingTimeInterval(10))

        #expect(isClose(engine.elapsed(at: base.addingTimeInterval(50)), 10))
        #expect(engine.state == .paused)
    }

    @Test("정지 후 재개하면 이전 경과 시간에 이어서 누적된다")
    func elapsedAccumulatesAcrossStopAndResume() {
        let engine = StopwatchEngine()
        engine.start(at: base)
        engine.stop(at: base.addingTimeInterval(10))
        engine.resume(at: base.addingTimeInterval(20))

        #expect(isClose(engine.elapsed(at: base.addingTimeInterval(25)), 15)) // 10 + (25 - 20)
    }

    @Test("리셋하면 경과 시간과 랩 목록이 함께 초기화된다")
    func resetClearsElapsedAndLaps() {
        let engine = StopwatchEngine()
        engine.start(at: base)
        engine.recordLap(at: base.addingTimeInterval(5))

        engine.reset()

        #expect(engine.state == .idle)
        #expect(engine.elapsed(at: base.addingTimeInterval(100)) == 0)
        #expect(engine.laps.isEmpty)
    }

    @Test("첫 랩은 시작 시점부터의 경과가 랩 소요 시간이 된다")
    func firstLapDurationEqualsElapsedSinceStart() throws {
        let engine = StopwatchEngine()
        engine.start(at: base)
        engine.recordLap(at: base.addingTimeInterval(8))

        let lap = try #require(engine.laps.first)
        #expect(lap.id == 1)
        #expect(isClose(lap.lapDuration, 8))
        #expect(isClose(lap.cumulativeDuration, 8))
    }

    @Test("두 번째 랩부터는 직전 랩 이후 경과가 랩 소요 시간이 된다")
    func subsequentLapDurationIsRelativeToPreviousLap() {
        let engine = StopwatchEngine()
        engine.start(at: base)
        engine.recordLap(at: base.addingTimeInterval(8)) // 랩 1: 8초
        engine.recordLap(at: base.addingTimeInterval(20)) // 랩 2: 12초 (20 - 8)

        #expect(engine.laps.count == 2)
        #expect(engine.laps[1].id == 2)
        #expect(isClose(engine.laps[1].lapDuration, 12))
        #expect(isClose(engine.laps[1].cumulativeDuration, 20))
    }

    @Test("랩은 개수 제한 없이 계속 기록할 수 있다")
    func lapsHaveNoCountLimit() {
        let engine = StopwatchEngine()
        engine.start(at: base)
        for i in 1 ... 50 {
            engine.recordLap(at: base.addingTimeInterval(Double(i)))
        }
        #expect(engine.laps.count == 50)
    }

    @Test("최댓값(99:59.99)을 넘기지 않고 그 값에서 멈추며 완료 상태가 된다")
    func elapsedClampsAtMaximumAndCompletes() {
        let engine = StopwatchEngine()
        engine.start(at: base)

        let value = engine.elapsed(at: base.addingTimeInterval(StopwatchEngine.maxElapsed + 100))

        #expect(value == StopwatchEngine.maxElapsed)
        #expect(engine.state == .completed)
    }

    @Test("0초는 00:00.00으로 표시된다")
    func formatsZeroElapsed() {
        #expect(StopwatchEngine.formattedClock(elapsed: 0) == "00:00.00")
    }

    @Test("최댓값(99:59.99)이 정확히 표시된다")
    func formatsMaximumValue() {
        #expect(StopwatchEngine.formattedClock(elapsed: StopwatchEngine.maxElapsed) == "99:59.99")
    }

    @Test("분/초/센티초가 정확히 계산된다")
    func formatsMinutesSecondsCentiseconds() {
        #expect(StopwatchEngine.formattedClock(elapsed: 65.43) == "01:05.43")
    }

    @Test("표시 가능한 최대치(99:59.99)를 넘거나 음수인 값은 clamp된다")
    func formattedClockClampsOutOfRangeValues() {
        #expect(StopwatchEngine.formattedClock(elapsed: StopwatchEngine.maxElapsed + 100) == "99:59.99")
        #expect(StopwatchEngine.formattedClock(elapsed: -5) == "00:00.00")
    }
}

//
//  TimerEngineTests.swift
//  tempoTests
//

import Foundation
@testable import tempo
import Testing

/// docs/testing-strategy.md 3번 항목: 시간 표시 포맷팅. 그 외 `TimerEngine`의 경과/잔여 시간
/// 계산과 상태 전이도 함께 검증한다. `Date`를 직접 주입해서 검증하므로 실제로 기다릴 필요가 없다.
@Suite("TimerEngine")
struct TimerEngineTests {
    private let base = Date()

    // MARK: - hours / minutes / seconds

    @Test("configuredSeconds를 시/분/초로 정확히 분해한다")
    func decomposesConfiguredSecondsIntoHoursMinutesSeconds() {
        let engine = TimerEngine(configuredSeconds: 3 * 3600 + 25 * 60 + 9)

        #expect(engine.hours == 3)
        #expect(engine.minutes == 25)
        #expect(engine.seconds == 9)
    }

    @Test("시/분/초를 따로 설정해도 나머지 값이 유지된다")
    func settingOnePartPreservesTheOthers() {
        let engine = TimerEngine(configuredSeconds: 3661) // 01:01:01

        engine.hours = 5
        #expect(engine.configuredSeconds == 5 * 3600 + 60 + 1)

        engine.minutes = 30
        #expect(engine.configuredSeconds == 5 * 3600 + 30 * 60 + 1)

        engine.seconds = 45
        #expect(engine.configuredSeconds == 5 * 3600 + 30 * 60 + 45)
    }

    // MARK: - elapsed(at:)

    @Test("시작 전에는 경과 시간이 0이다")
    func elapsedIsZeroBeforeStart() {
        let engine = TimerEngine(configuredSeconds: 60)
        #expect(engine.elapsed(at: base) == 0)
    }

    @Test("시작 후 경과 시간이 흐른 시간만큼 증가한다")
    func elapsedIncreasesAfterStart() {
        let engine = TimerEngine(configuredSeconds: 60)
        engine.start(at: base)

        #expect(engine.elapsed(at: base.addingTimeInterval(10)) == 10)
    }

    @Test("일시정지하면 그 시점 경과 시간에서 멈춘다")
    func elapsedFreezesWhenPaused() {
        let engine = TimerEngine(configuredSeconds: 60)
        engine.start(at: base)
        engine.pause(at: base.addingTimeInterval(10))

        // 일시정지 후 시간이 더 흘러도(now가 계속 지나도) 경과 시간은 그대로다.
        #expect(engine.elapsed(at: base.addingTimeInterval(50)) == 10)
    }

    @Test("일시정지 후 재개하면 이전 경과 시간에 이어서 누적된다")
    func elapsedAccumulatesAcrossPauseAndResume() {
        let engine = TimerEngine(configuredSeconds: 60)
        engine.start(at: base)
        engine.pause(at: base.addingTimeInterval(10))
        engine.resume(at: base.addingTimeInterval(20))

        #expect(engine.elapsed(at: base.addingTimeInterval(25)) == 15) // 10 + (25 - 20)
    }

    // MARK: - remainingOrElapsedSeconds(at:) — 카운트다운

    @Test("카운트다운은 설정 시간에서 경과 시간만큼 감소한다")
    func countdownDecreasesFromConfiguredSeconds() {
        let engine = TimerEngine(mode: .countdown, configuredSeconds: 30)
        engine.start(at: base)

        #expect(engine.remainingOrElapsedSeconds(at: base.addingTimeInterval(12)) == 18)
        #expect(engine.state == .running)
    }

    @Test("카운트다운이 설정 시간에 도달하면 0에서 멈추고 완료 상태가 된다")
    func countdownCompletesAtZero() {
        let engine = TimerEngine(mode: .countdown, configuredSeconds: 30)
        engine.start(at: base)

        #expect(engine.remainingOrElapsedSeconds(at: base.addingTimeInterval(30)) == 0)
        #expect(engine.state == .completed)
    }

    @Test("카운트다운은 설정 시간을 넘겨도 음수가 아니라 0을 반환한다")
    func countdownNeverGoesNegative() {
        let engine = TimerEngine(mode: .countdown, configuredSeconds: 30)
        engine.start(at: base)

        #expect(engine.remainingOrElapsedSeconds(at: base.addingTimeInterval(100)) == 0)
        #expect(engine.state == .completed)
    }

    // MARK: - remainingOrElapsedSeconds(at:) — 카운트업

    @Test("카운트업은 0부터 경과 시간만큼 증가한다")
    func countUpIncreasesFromZero() {
        let engine = TimerEngine(mode: .countUp, configuredSeconds: 30)
        engine.start(at: base)

        #expect(engine.remainingOrElapsedSeconds(at: base.addingTimeInterval(12)) == 12)
        #expect(engine.state == .running)
    }

    @Test("카운트업이 설정 시간에 도달하면 그 값에서 멈추고 완료 상태가 된다")
    func countUpCompletesAtConfiguredSeconds() {
        let engine = TimerEngine(mode: .countUp, configuredSeconds: 30)
        engine.start(at: base)

        #expect(engine.remainingOrElapsedSeconds(at: base.addingTimeInterval(30)) == 30)
        #expect(engine.state == .completed)
    }

    @Test("카운트업은 설정 시간을 넘겨도 그 값에서 고정된다")
    func countUpClampsAtConfiguredSeconds() {
        let engine = TimerEngine(mode: .countUp, configuredSeconds: 30)
        engine.start(at: base)

        #expect(engine.remainingOrElapsedSeconds(at: base.addingTimeInterval(100)) == 30)
        #expect(engine.state == .completed)
    }

    // MARK: - 상태 전이

    @Test("초기 상태는 idle이다")
    func initialStateIsIdle() {
        let engine = TimerEngine()
        #expect(engine.state == .idle)
    }

    @Test("시작하면 running이 된다")
    func startTransitionsToRunning() {
        let engine = TimerEngine(configuredSeconds: 60)
        engine.start(at: base)
        #expect(engine.state == .running)
    }

    @Test("리셋하면 idle로 돌아가고 경과 시간이 초기화된다")
    func resetReturnsToIdleAndClearsElapsed() {
        let engine = TimerEngine(mode: .countdown, configuredSeconds: 30)
        engine.start(at: base)
        _ = engine.remainingOrElapsedSeconds(at: base.addingTimeInterval(30)) // 완료 상태로 만든다
        #expect(engine.state == .completed)

        engine.reset()

        #expect(engine.state == .idle)
        #expect(engine.elapsed(at: base.addingTimeInterval(100)) == 0)
    }

    // MARK: - formattedClock(seconds:)

    @Test("0초는 00:00:00으로 표시된다")
    func formatsZeroSeconds() {
        #expect(TimerEngine.formattedClock(seconds: 0) == "00:00:00")
    }

    @Test("최댓값(23:59:59)이 정확히 표시된다")
    func formatsMaximumValue() {
        #expect(TimerEngine.formattedClock(seconds: 23 * 3600 + 59 * 60 + 59) == "23:59:59")
    }

    @Test("한 자리 시/분/초도 0으로 채워서 두 자리로 표시된다")
    func padsSingleDigitComponents() {
        #expect(TimerEngine.formattedClock(seconds: 3661) == "01:01:01") // 1시간 1분 1초
    }
}

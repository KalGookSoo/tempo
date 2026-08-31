//
//  IntervalRunnerTests.swift
//  tempoTests
//

import Foundation
@testable import tempo
import Testing

/// docs/testing-strategy.md 1번 항목: 인터벌 실행 시퀀스 계산. "피라미드 인터벌"과 "EMOM"
/// 예시(docs/timer-functional-spec.md "인터벌 예시 2", "EMOM 예시")를 그대로 테스트 케이스로
/// 옮긴다. 그 외 진행/일시정지/재개/완료 전이도 함께 검증한다.
@Suite("IntervalRunner")
struct IntervalRunnerTests {
    private let base = Date()

    // MARK: - expandSteps: 피라미드 인터벌 (인터벌 예시 2)

    @Test("피라미드 인터벌은 6구간씩 8라운드, 총 48구간으로 펼쳐진다")
    func pyramidIntervalExpandsToFortyEightSteps() {
        let config = IntervalConfig(
            rounds: 8,
            prepareSeconds: 0,
            segments: [
                IntervalSegment(type: .work, seconds: 90),
                IntervalSegment(type: .rest, seconds: 30),
                IntervalSegment(type: .work, seconds: 60),
                IntervalSegment(type: .rest, seconds: 20),
                IntervalSegment(type: .work, seconds: 30),
                IntervalSegment(type: .rest, seconds: 10),
            ]
        )

        let steps = IntervalRunner.expandSteps(config: config)

        #expect(steps.count == 48)
    }

    @Test("피라미드 인터벌 1라운드의 실행 순서가 명세와 정확히 일치한다")
    func pyramidIntervalFirstRoundMatchesSpec() {
        let config = IntervalConfig(
            rounds: 8,
            prepareSeconds: 0,
            segments: [
                IntervalSegment(type: .work, seconds: 90),
                IntervalSegment(type: .rest, seconds: 30),
                IntervalSegment(type: .work, seconds: 60),
                IntervalSegment(type: .rest, seconds: 20),
                IntervalSegment(type: .work, seconds: 30),
                IntervalSegment(type: .rest, seconds: 10),
            ]
        )

        let firstRound = IntervalRunner.expandSteps(config: config).prefix(6)

        #expect(firstRound.map(\.label) == ["F1", "C1", "F2", "C2", "F3", "C3"])
        #expect(firstRound.map(\.seconds) == [90, 30, 60, 20, 30, 10])
        #expect(firstRound.allSatisfy { $0.round == 1 && $0.totalRounds == 8 })
    }

    @Test("피라미드 인터벌은 매 라운드마다 F1/C1/F2/C2/F3/C3 라벨이 그대로 반복된다")
    func pyramidIntervalLabelsRepeatEveryRound() {
        let config = IntervalConfig(
            rounds: 8,
            prepareSeconds: 0,
            segments: [
                IntervalSegment(type: .work, seconds: 90),
                IntervalSegment(type: .rest, seconds: 30),
                IntervalSegment(type: .work, seconds: 60),
                IntervalSegment(type: .rest, seconds: 20),
                IntervalSegment(type: .work, seconds: 30),
                IntervalSegment(type: .rest, seconds: 10),
            ]
        )

        let steps = IntervalRunner.expandSteps(config: config)
        let secondRound = steps[6 ..< 12]

        #expect(secondRound.map(\.label) == ["F1", "C1", "F2", "C2", "F3", "C3"])
        #expect(secondRound.allSatisfy { $0.round == 2 })
    }

    // MARK: - expandSteps: EMOM

    @Test("EMOM은 휴식 0초 구간을 건너뛰고 라운드당 1구간(F1)만 갖는다")
    func emomSkipsZeroSecondRestAndKeepsOnlyWorkStep() {
        let config = IntervalConfig(
            rounds: 10,
            prepareSeconds: 0,
            segments: [
                IntervalSegment(type: .work, seconds: 60),
                IntervalSegment(type: .rest, seconds: 0),
            ]
        )

        let steps = IntervalRunner.expandSteps(config: config)

        #expect(steps.count == 10)
        #expect(steps.allSatisfy { $0.label == "F1" && $0.seconds == 60 && $0.kind == .work })
        #expect(steps.map(\.round) == Array(1 ... 10))
    }

    // MARK: - expandSteps: 준비 카운트다운

    @Test("준비 시간이 있으면 맨 앞에 준비 구간이 추가된다")
    func prepareStepIsPrependedWhenConfigured() {
        let config = IntervalConfig(
            rounds: 1,
            prepareSeconds: 10,
            segments: [IntervalSegment(type: .work, seconds: 20)]
        )

        let steps = IntervalRunner.expandSteps(config: config)

        #expect(steps.first?.kind == .prepare)
        #expect(steps.first?.label == "준비")
        #expect(steps.first?.seconds == 10)
        #expect(steps.first?.round == 0)
    }

    @Test("준비 시간이 0이면 준비 구간이 없다")
    func prepareStepIsOmittedWhenZero() {
        let config = IntervalConfig(
            rounds: 1,
            prepareSeconds: 0,
            segments: [IntervalSegment(type: .work, seconds: 20)]
        )

        let steps = IntervalRunner.expandSteps(config: config)

        #expect(steps.first?.kind != .prepare)
    }

    // MARK: - 진행(currentProgress)

    private func makeSimpleTwoRoundConfig() -> IntervalConfig {
        // 라운드당 F1(20초)+C1(10초) = 30초, 2라운드 = 총 60초.
        IntervalConfig(
            rounds: 2,
            prepareSeconds: 0,
            segments: [
                IntervalSegment(type: .work, seconds: 20),
                IntervalSegment(type: .rest, seconds: 10),
            ]
        )
    }

    @Test("경과 시간에 따라 올바른 구간과 남은 시간을 계산한다")
    func currentProgressTracksElapsedAcrossSteps() {
        let runner = IntervalRunner(config: makeSimpleTwoRoundConfig())
        runner.start(at: base)

        let atFiveSeconds = runner.currentProgress(at: base.addingTimeInterval(5))
        #expect(atFiveSeconds?.stepIndex == 0)
        #expect(atFiveSeconds?.step.label == "F1")
        #expect(atFiveSeconds?.remainingSeconds == 15)

        let atTwentyFive = runner.currentProgress(at: base.addingTimeInterval(25))
        #expect(atTwentyFive?.stepIndex == 1)
        #expect(atTwentyFive?.step.label == "C1")
        #expect(atTwentyFive?.remainingSeconds == 5)

        let atThirtyFive = runner.currentProgress(at: base.addingTimeInterval(35))
        #expect(atThirtyFive?.stepIndex == 2)
        #expect(atThirtyFive?.step.round == 2)
        #expect(atThirtyFive?.remainingSeconds == 15)

        let atFiftyFive = runner.currentProgress(at: base.addingTimeInterval(55))
        #expect(atFiftyFive?.stepIndex == 3)
        #expect(atFiftyFive?.remainingSeconds == 5)
    }

    @Test("모든 구간이 끝나면 completed 상태가 되고 진행 정보는 nil이다")
    func currentProgressReturnsNilAndCompletesAfterAllSteps() {
        let runner = IntervalRunner(config: makeSimpleTwoRoundConfig())
        runner.start(at: base)

        let progress = runner.currentProgress(at: base.addingTimeInterval(65))

        #expect(progress == nil)
        #expect(runner.state == .completed)
    }

    @Test("일시정지하면 그 시점 진행 상태에서 멈춘다")
    func pauseFreezesProgress() {
        let runner = IntervalRunner(config: makeSimpleTwoRoundConfig())
        runner.start(at: base)
        runner.pause(at: base.addingTimeInterval(5))

        let progress = runner.currentProgress(at: base.addingTimeInterval(50))

        #expect(progress?.stepIndex == 0)
        #expect(progress?.remainingSeconds == 15)
        #expect(runner.state == .paused)
    }

    @Test("일시정지 후 재개하면 이어서 진행된다")
    func resumeContinuesFromPausedProgress() {
        let runner = IntervalRunner(config: makeSimpleTwoRoundConfig())
        runner.start(at: base)
        runner.pause(at: base.addingTimeInterval(5)) // F1 5초 경과에서 정지
        runner.resume(at: base.addingTimeInterval(20)) // 20초 뒤에 재개

        // 재개 시점(20) + 10초 더 지남 = 논리적으로는 F1 시작 후 15초 경과와 동일해야 한다.
        let progress = runner.currentProgress(at: base.addingTimeInterval(30))

        #expect(progress?.stepIndex == 0)
        #expect(progress?.remainingSeconds == 5)
        #expect(runner.state == .running)
    }

    @Test("전체 시퀀스가 끝난 뒤에 일시정지했다가 재개하면 곧바로 완료 상태여야 한다")
    func resumingAfterSequenceEndedShouldStayCompleted() {
        let config = IntervalConfig(
            rounds: 1,
            prepareSeconds: 0,
            segments: [
                IntervalSegment(type: .work, seconds: 10),
                IntervalSegment(type: .rest, seconds: 0),
            ]
        )
        let runner = IntervalRunner(config: config)
        runner.start(at: base)

        // F1(10초)짜리 구간 하나뿐인데, 13초(이미 다 끝난 뒤) 지나서 일시정지한다.
        runner.pause(at: base.addingTimeInterval(13))
        runner.resume(at: base.addingTimeInterval(50))

        #expect(runner.state == .completed)
        #expect(runner.currentProgress(at: base.addingTimeInterval(50)) == nil)
    }

    @Test("준비 구간에서 시작하면 상태가 preparing이 된다")
    func startsInPreparingStateWhenPrepareStepExists() {
        let config = IntervalConfig(
            rounds: 1,
            prepareSeconds: 5,
            segments: [IntervalSegment(type: .work, seconds: 20)]
        )
        let runner = IntervalRunner(config: config)
        runner.start(at: base)

        #expect(runner.state == .preparing)
    }

    @Test("리셋하면 idle로 돌아간다")
    func resetReturnsToIdle() {
        let runner = IntervalRunner(config: makeSimpleTwoRoundConfig())
        runner.start(at: base)
        _ = runner.currentProgress(at: base.addingTimeInterval(65)) // 완료 상태로 만든다

        runner.reset()

        #expect(runner.state == .idle)
        #expect(runner.currentProgress(at: base.addingTimeInterval(1))?.stepIndex == 0)
    }

    // MARK: - formattedClock(seconds:)

    @Test("MM:SS 형식으로 표시된다")
    func formatsMinutesAndSeconds() {
        #expect(IntervalRunner.formattedClock(seconds: 90) == "01:30")
        #expect(IntervalRunner.formattedClock(seconds: 5) == "00:05")
    }
}

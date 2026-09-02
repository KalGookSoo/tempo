import Foundation
@testable import tempo
import Testing

/// docs/testing-strategy.md 4번 항목: 알림 큐 트리거 판정. 8개 이벤트(준비 카운트다운 시작/
/// 시작 전 카운트다운/운동 시작/휴식 시작/구간 종료/라운드 종료/마지막 라운드 진입/전체 종료)
/// 각각 최소 1개 케이스를 둔다. `IntervalRunner.expandSteps`로 만든 실제 구간 배열을 그대로
/// 써서 판정 함수(순수 함수, Date 불필요)를 검증한다.
@Suite("CueEventDetector")
struct CueEventDetectorTests {
    /// 준비 5초 -> [F1 20초, C1 10초] x 2라운드.
    /// steps[0]=준비, [1]=1R F1, [2]=1R C1, [3]=2R F1(마지막 라운드), [4]=2R C1(마지막 구간).
    private func makeSteps() -> [IntervalStep] {
        let config = IntervalConfig(
            rounds: 2,
            prepareSeconds: 5,
            segments: [
                IntervalSegment(type: .work, seconds: 20),
                IntervalSegment(type: .rest, seconds: 10),
            ]
        )
        return IntervalRunner.expandSteps(config: config)
    }

    @Test("아직 시작하지 않았으면 아무 이벤트도 발동하지 않는다")
    func noEventsBeforeStart() {
        let events = CueEventDetector.events(previousStep: nil, currentProgress: nil, countdownLeadSeconds: 0)
        #expect(events.isEmpty)
    }

    @Test("1구간(준비)에 진입하면 준비 카운트다운 시작 이벤트가 발동한다")
    func prepareStartFires() {
        let steps = makeSteps()
        let progress = IntervalRunner.Progress(stepIndex: 0, step: steps[0], remainingSeconds: 5, elapsedInStep: 0)

        let events = CueEventDetector.events(previousStep: nil, currentProgress: progress, countdownLeadSeconds: 0)

        #expect(events.contains(.prepareStart))
    }

    @Test("남은 시간이 알림 시점 이하로 떨어지면 시작 전 카운트다운 이벤트가 발동한다")
    func countdownLeadFires() {
        let steps = makeSteps()
        let progress = IntervalRunner.Progress(stepIndex: 1, step: steps[1], remainingSeconds: 2, elapsedInStep: 18)

        let events = CueEventDetector.events(previousStep: steps[1], currentProgress: progress, countdownLeadSeconds: 3)

        #expect(events.contains(.countdownLead(secondsRemaining: 2)))
    }

    @Test("구간이 안 바뀌고 알림 시점 범위 밖이면 아무 이벤트도 없다")
    func noEventsWhenNothingChangedAndOutsideLeadWindow() {
        let steps = makeSteps()
        let progress = IntervalRunner.Progress(stepIndex: 1, step: steps[1], remainingSeconds: 15, elapsedInStep: 5)

        let events = CueEventDetector.events(previousStep: steps[1], currentProgress: progress, countdownLeadSeconds: 3)

        #expect(events.isEmpty)
    }

    @Test("준비 구간에서 첫 운동 구간으로 넘어가면 구간 종료 + 운동 시작이 발동하고 라운드 종료는 발동하지 않는다")
    func workStartAndSegmentEndFireFromPrepare() {
        let steps = makeSteps()
        let progress = IntervalRunner.Progress(stepIndex: 1, step: steps[1], remainingSeconds: 20, elapsedInStep: 0)

        let events = CueEventDetector.events(previousStep: steps[0], currentProgress: progress, countdownLeadSeconds: 0)

        #expect(events.contains(.workStart))
        #expect(events.contains(.segmentEnd))
        #expect(!events.contains(.roundEnd))
        #expect(!events.contains(.finalRoundEnter)) // 2라운드 중 1라운드라 마지막 라운드가 아니다
    }

    @Test("운동 구간에서 휴식 구간으로 넘어가면 구간 종료 + 휴식 시작이 발동한다")
    func restStartAndSegmentEndFire() {
        let steps = makeSteps()
        let progress = IntervalRunner.Progress(stepIndex: 2, step: steps[2], remainingSeconds: 10, elapsedInStep: 0)

        let events = CueEventDetector.events(previousStep: steps[1], currentProgress: progress, countdownLeadSeconds: 0)

        #expect(events.contains(.restStart))
        #expect(events.contains(.segmentEnd))
    }

    @Test("마지막 라운드로 넘어가면 라운드 종료 + 마지막 라운드 진입 + 운동 시작이 함께 발동한다")
    func roundEndAndFinalRoundEnterFireEnteringLastRound() {
        let steps = makeSteps()
        let progress = IntervalRunner.Progress(stepIndex: 3, step: steps[3], remainingSeconds: 20, elapsedInStep: 0)

        let events = CueEventDetector.events(previousStep: steps[2], currentProgress: progress, countdownLeadSeconds: 0)

        #expect(events.contains(.roundEnd))
        #expect(events.contains(.finalRoundEnter))
        #expect(events.contains(.workStart))
    }

    @Test("마지막 라운드 안에서는 구간이 바뀌어도 마지막 라운드 진입이 다시 발동하지 않는다")
    func finalRoundEnterDoesNotRefireWithinSameRound() {
        let steps = makeSteps()
        let progress = IntervalRunner.Progress(stepIndex: 4, step: steps[4], remainingSeconds: 10, elapsedInStep: 0)

        let events = CueEventDetector.events(previousStep: steps[3], currentProgress: progress, countdownLeadSeconds: 0)

        #expect(!events.contains(.finalRoundEnter))
        #expect(events.contains(.restStart))
    }

    @Test("마지막 구간이 끝나 전체 시퀀스가 완료되면 라운드 종료 + 전체 종료가 발동한다")
    func roundEndAndFinishFireAtSequenceEnd() {
        let steps = makeSteps()

        let events = CueEventDetector.events(previousStep: steps[4], currentProgress: nil, countdownLeadSeconds: 0)

        #expect(events.contains(.roundEnd))
        #expect(events.contains(.finish))
    }

    @Test("event(for:in:)는 이벤트 종류에 맞는 CueConfig.Event를 꺼내고, countdownLead는 nil을 반환한다")
    func eventForKindMapsToConfig() {
        let workEvent = CueConfig.Event(mode: .sound, soundAssetID: nil)
        let finishEvent = CueConfig.Event(mode: .vibration, soundAssetID: nil)
        let config = CueConfig(
            countdownLeadSeconds: 3,
            prepareStart: .init(mode: .none, soundAssetID: nil),
            workStart: workEvent,
            restStart: .init(mode: .none, soundAssetID: nil),
            segmentEnd: .init(mode: .none, soundAssetID: nil),
            roundEnd: .init(mode: .none, soundAssetID: nil),
            finalRoundEnter: .init(mode: .none, soundAssetID: nil),
            finish: finishEvent
        )

        #expect(CueEventDetector.event(for: .workStart, in: config) == workEvent)
        #expect(CueEventDetector.event(for: .finish, in: config) == finishEvent)
        #expect(CueEventDetector.event(for: .countdownLead(secondsRemaining: 2), in: config) == nil)
    }
}

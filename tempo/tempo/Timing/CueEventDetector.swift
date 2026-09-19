import Foundation

/// `docs/timer-functional-spec.md` "알림 큐"가 정의한 이벤트들. `workEnd`는
/// 이슈 #75에서 추가됐다.
enum CueEventKind: Equatable {
    case prepareStart
    case countdownLead(secondsRemaining: Int)
    case workStart
    case restStart
    case segmentEnd
    case workEnd
    case roundEnd
    case finalRoundEnter
    case finish
}

/// 이전/현재 진행 상태를 비교해서 "지금 어떤 알림 이벤트가 발동해야 하는가"를 판정하는
/// View/엔진 밖 순수 함수. `IntervalRunner`가 매 틱(1초) 계산해주는 `Progress`를 그대로
/// 입력으로 받는다. docs/testing-strategy.md 4번 항목 참고.
enum CueEventDetector {
    /// 구간 하나가 끝나고 다음 구간(`currentStep`)으로 넘어가는 순간 발동하는 이벤트들.
    /// `previousStep`이 `nil`이면(맨 처음 진입) 종료 계열 이벤트 없이 시작 계열만 낸다.
    /// `events(...)`의 "구간이 바뀌었을 때" 분기와 `upcomingEvents(...)`가 미래의 각
    /// 구간 전환마다 이 로직을 반복 재사용한다 — 판정 규칙이 두 곳에서 따로 놀지 않게
    /// 한 곳에만 둔다.
    private static func transitionEvents(from previousStep: IntervalStep?, to currentStep: IntervalStep) -> [CueEventKind] {
        var events: [CueEventKind] = []

        if let previousStep {
            events.append(.segmentEnd)
            if previousStep.kind == .work {
                events.append(.workEnd)
            }
            if previousStep.round != currentStep.round, previousStep.round != 0 {
                events.append(.roundEnd)
            }
        }

        switch currentStep.kind {
        case .prepare:
            events.append(.prepareStart)
        case .work:
            events.append(.workStart)
            if currentStep.round == currentStep.totalRounds, previousStep?.round != currentStep.round {
                events.append(.finalRoundEnter)
            }
        case .rest:
            events.append(.restStart)
        }

        return events
    }

    /// 마지막 구간(`lastStep`)까지 다 끝나 전체 시퀀스가 완료됐을 때 발동하는 이벤트들.
    private static func finishEvents(lastStep: IntervalStep) -> [CueEventKind] {
        lastStep.round == 0 ? [.finish] : [.roundEnd, .finish]
    }

    static func events(
        previousStep: IntervalStep?,
        currentProgress: IntervalRunner.Progress?,
        countdownLeadSeconds: Int
    ) -> [CueEventKind] {
        guard let currentProgress else {
            guard let previousStep else { return [] }
            return finishEvents(lastStep: previousStep)
        }

        let currentStep = currentProgress.step
        var events: [CueEventKind] = []
        let didAdvanceToNewStep = previousStep?.id != currentStep.id

        if didAdvanceToNewStep {
            events = transitionEvents(from: previousStep, to: currentStep)
        }

        // 구간이 막 시작된 틱에는 카운트다운 알림을 안 울린다. 구간 길이가 알림
        // 시점(countdownLeadSeconds)보다 짧거나 같으면(예: 운동 5초 + 알림 시점 10초)
        // 시작하자마자 remainingSeconds가 이미 그 범위 안에 들어와서 시작 알림
        // (workStart/restStart)과 카운트다운 알림이 같은 틱에 겹쳐 울렸다.
        if !didAdvanceToNewStep,
           countdownLeadSeconds > 0,
           currentProgress.remainingSeconds > 0,
           currentProgress.remainingSeconds <= countdownLeadSeconds
        {
            events.append(.countdownLead(secondsRemaining: currentProgress.remainingSeconds))
        }

        return events
    }

    /// 알림 큐 이벤트 하나와, 지금부터 몇 초 뒤에 발생하는지를 함께 담는다.
    struct ScheduledCueEvent: Equatable {
        let kind: CueEventKind
        let secondsUntil: Int
    }

    /// 지금(`progress`)부터 인터벌이 완전히 끝날 때까지 앞으로 발생할 모든 이벤트를,
    /// 각각 몇 초 뒤에 발생하는지와 함께 발생 순서대로 전부 계산한다. `events(...)`가
    /// "이번 틱에 당장 뭐가 발동해야 하냐"만 알려주는 실시간 판정용인 것과 달리, 이
    /// 함수는 백그라운드 알림을 시작/재개 시점에 한꺼번에 예약해두기 위해(#109) 미래
    /// 전체를 미리 내다본다.
    static func upcomingEvents(steps: [IntervalStep], from progress: IntervalRunner.Progress) -> [ScheduledCueEvent] {
        var results: [ScheduledCueEvent] = []
        var cursor = progress.remainingSeconds
        var previousStep = progress.step

        for currentStep in steps[(progress.stepIndex + 1)...] {
            for kind in transitionEvents(from: previousStep, to: currentStep) {
                results.append(ScheduledCueEvent(kind: kind, secondsUntil: cursor))
            }
            cursor += currentStep.seconds
            previousStep = currentStep
        }

        for kind in finishEvents(lastStep: previousStep) {
            results.append(ScheduledCueEvent(kind: kind, secondsUntil: cursor))
        }

        return results
    }

    /// `CueEventKind`에 해당하는 `CueConfig.Event` 설정을 꺼낸다. `countdownLead`는 별도
    /// 설정이 없어(공용 시작 전 알림 시점만 있음) `nil`을 반환한다 — 호출부에서 필요하면
    /// 별도 처리한다.
    static func event(for kind: CueEventKind, in config: CueConfig) -> CueConfig.Event? {
        switch kind {
        case .prepareStart: config.prepareStart
        case .workStart: config.workStart
        case .restStart: config.restStart
        case .segmentEnd: config.segmentEnd
        case .workEnd: config.workEnd
        case .roundEnd: config.roundEnd
        case .finalRoundEnter: config.finalRoundEnter
        case .finish: config.finish
        case .countdownLead: nil
        }
    }
}

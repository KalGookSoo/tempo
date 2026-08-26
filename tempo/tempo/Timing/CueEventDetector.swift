//
//  CueEventDetector.swift
//  tempo
//

import Foundation

/// `docs/timer-functional-spec.md` "알림 큐"가 정의한 8개 이벤트.
enum CueEventKind: Equatable {
    case prepareStart
    case countdownLead(secondsRemaining: Int)
    case workStart
    case restStart
    case segmentEnd
    case roundEnd
    case finalRoundEnter
    case finish
}

/// 이전/현재 진행 상태를 비교해서 "지금 어떤 알림 이벤트가 발동해야 하는가"를 판정하는
/// View/엔진 밖 순수 함수. `IntervalRunner`가 매 틱(1초) 계산해주는 `Progress`를 그대로
/// 입력으로 받는다. docs/testing-strategy.md 4번 항목 참고.
enum CueEventDetector {
    static func events(
        previousStep: IntervalStep?,
        currentProgress: IntervalRunner.Progress?,
        countdownLeadSeconds: Int
    ) -> [CueEventKind] {
        guard let currentProgress else {
            guard let previousStep else { return [] }
            return previousStep.round == 0 ? [.finish] : [.roundEnd, .finish]
        }

        let currentStep = currentProgress.step
        var events: [CueEventKind] = []
        let didAdvanceToNewStep = previousStep?.id != currentStep.id

        if didAdvanceToNewStep {
            if let previousStep {
                events.append(.segmentEnd)
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
        }

        if countdownLeadSeconds > 0,
           currentProgress.remainingSeconds > 0,
           currentProgress.remainingSeconds <= countdownLeadSeconds
        {
            events.append(.countdownLead(secondsRemaining: currentProgress.remainingSeconds))
        }

        return events
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
        case .roundEnd: config.roundEnd
        case .finalRoundEnter: config.finalRoundEnter
        case .finish: config.finish
        case .countdownLead: nil
        }
    }
}

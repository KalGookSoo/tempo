import Foundation
import Observation

/// 실행 순서로 펼쳐진 구간 하나(준비/운동/휴식). `docs/timer-functional-spec.md`
/// "인터벌 실행 순서" 참고.
struct IntervalStep: Identifiable, Equatable {
    enum Kind {
        case prepare
        case work
        case rest
    }

    let id: Int
    /// 1부터 시작. 준비 구간은 0.
    let round: Int
    let totalRounds: Int
    /// 준비 구간은 "준비", 그 외에는 "F1"/"C1"처럼 라운드 안에서의 세트 순번을 붙인 라벨.
    let label: String
    let kind: Kind
    let seconds: Int
}

/// `IntervalConfig`를 실제로 진행시키는 View 밖 순수 계산 엔진. `TimerEngine`/
/// `StopwatchEngine`과 같은 방식(Date 주입)으로 계산하므로 실제로 기다릴 필요가 없다.
/// docs/testing-strategy.md 1번 항목(인터벌 실행 시퀀스 계산) 참고.
@Observable
final class IntervalRunner {
    let steps: [IntervalStep]
    var state: TimerState

    private var startedAt: Date?
    private var pausedElapsed: TimeInterval

    struct Progress: Equatable {
        let stepIndex: Int
        let step: IntervalStep
        let remainingSeconds: Int
        /// 이 구간 안에서 지금까지 지난 시간(초, 소수점 포함). `remainingSeconds`는 정수
        /// 초 단위라 원형 프로그레스 링을 채우는 용도로 쓰면 매초 한 번씩만 갱신되는데,
        /// 이 값은 실제 경과 시간 그대로라 더 촘촘한 주기로 갱신해도 매끄럽게 채워진다.
        let elapsedInStep: TimeInterval
    }

    init(config: IntervalConfig) {
        steps = Self.expandSteps(config: config)
        state = .idle
        startedAt = nil
        pausedElapsed = 0
    }

    // MARK: - 시퀀스 펼치기

    /// `IntervalConfig`를 "준비(있으면) → 1라운드 F1,C1,... → 2라운드 F1,C1,... → ..."
    /// 순서의 평평한 배열로 펼친다. 휴식 시간이 0초인 구간은 건너뛴다.
    static func expandSteps(config: IntervalConfig) -> [IntervalStep] {
        var steps: [IntervalStep] = []
        var nextID = 1

        if config.prepareSeconds > 0 {
            steps.append(IntervalStep(
                id: nextID,
                round: 0,
                totalRounds: config.rounds,
                label: "준비",
                kind: .prepare,
                seconds: config.prepareSeconds
            ))
            nextID += 1
        }

        // 라운드 안에서의 세트 순번(F1/C1/F2/C2...)은 라운드마다 동일하므로 한 번만 계산한다.
        var workCount = 0
        var restCount = 0
        let labels: [String] = config.segments.map { segment in
            switch segment.type {
            case .work:
                workCount += 1
                return "F\(workCount)"
            case .rest:
                restCount += 1
                return "C\(restCount)"
            }
        }

        guard config.rounds > 0 else { return steps }

        for round in 1 ... config.rounds {
            for (index, segment) in config.segments.enumerated() {
                if segment.type == .rest, segment.seconds == 0 {
                    continue
                }
                steps.append(IntervalStep(
                    id: nextID,
                    round: round,
                    totalRounds: config.rounds,
                    label: labels[index],
                    kind: segment.type == .work ? .work : .rest,
                    seconds: segment.seconds
                ))
                nextID += 1
            }
        }

        return steps
    }

    // MARK: - 진행 조회

    /// 시작(또는 재개) 이후 전체 경과 시간. 여러 구간에 걸쳐 계속 누적된다.
    func totalElapsed(at now: Date) -> TimeInterval {
        startedAt.map { pausedElapsed + now.timeIntervalSince($0) } ?? pausedElapsed
    }

    /// 지금 시각 기준으로 어느 구간의 몇 초가 남았는지 계산한다. 전체 시퀀스가 끝났으면
    /// `nil`을 반환하고 `state`를 `.completed`로 전이시킨다.
    func currentProgress(at now: Date) -> Progress? {
        let progress = progress(atElapsed: totalElapsed(at: now))
        if progress == nil, state == .running || state == .preparing {
            state = .completed
            startedAt = nil
        }
        return progress
    }

    private func progress(atElapsed elapsed: TimeInterval) -> Progress? {
        var cursor: TimeInterval = 0
        for (index, step) in steps.enumerated() {
            let duration = TimeInterval(step.seconds)
            let elapsedInStep = elapsed - cursor
            if elapsedInStep < duration {
                let remaining = step.seconds - Int(elapsedInStep)
                return Progress(
                    stepIndex: index,
                    step: step,
                    remainingSeconds: max(remaining, 0),
                    elapsedInStep: max(elapsedInStep, 0)
                )
            }
            cursor += duration
        }
        return nil
    }

    // MARK: - 조작

    func start(at now: Date) {
        guard let first = steps.first else { return }
        state = first.kind == .prepare ? .preparing : .running
        startedAt = now
        pausedElapsed = 0
    }

    func pause(at now: Date) {
        pausedElapsed = totalElapsed(at: now)
        startedAt = nil
        state = .paused
    }

    func resume(at now: Date) {
        guard let step = progress(atElapsed: pausedElapsed)?.step else {
            state = .completed
            startedAt = nil
            return
        }
        state = step.kind == .prepare ? .preparing : .running
        startedAt = now
    }

    func reset() {
        state = .idle
        startedAt = nil
        pausedElapsed = 0
    }

    /// `MM:SS` 문자열로 표시한다 (인터벌 구간은 `HH:MM:SS`가 아니라 `Fn MM:SS` 형식을 쓴다).
    /// 화면에 표시 가능한 최대치(99:59)로 clamp한 뒤 포맷한다. 호출부가 항상 유효한
    /// 범위의 값을 넘겨주지만, 그 보장이 깨지는 경우(데이터 임포트, 마이그레이션 등)에도
    /// 항상 유효한 형식의 문자열만 보여주기 위한 사전 안전장치다(이슈 #34).
    static func formattedClock(seconds: Int) -> String {
        let clamped = max(0, min(seconds, 5999))
        let minutes = clamped / 60
        let secs = clamped % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

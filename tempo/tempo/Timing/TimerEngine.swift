import Foundation
import Observation

@Observable
final class TimerEngine {
    var mode: TimerMode
    var state: TimerState
    var configuredSeconds: Int
    var label: String
    var endSoundAssetID: UUID?

    var hours: Int {
        get {
            configuredSeconds / 3600
        }
        set {
            configuredSeconds = newValue * 3600 + minutes * 60 + seconds
        }
    }

    var minutes: Int {
        get {
            (configuredSeconds % 3600) / 60
        }
        set {
            configuredSeconds = hours * 3600 + newValue * 60 + seconds
        }
    }

    var seconds: Int {
        get {
            configuredSeconds % 60
        }
        set {
            configuredSeconds = hours * 3600 + minutes * 60 + newValue
        }
    }

    private var startedAt: Date?
    private var pausedElapsed: TimeInterval

    init(
        mode: TimerMode = .countdown,
        configuredSeconds: Int = 0,
        label: String = "",
        endSoundAssetID: UUID? = nil
    ) {
        self.mode = mode
        state = .idle
        self.configuredSeconds = configuredSeconds
        self.label = label
        self.endSoundAssetID = endSoundAssetID
        startedAt = nil
        pausedElapsed = 0
    }

    func elapsed(at now: Date) -> TimeInterval {
        guard let startedAt else {
            return pausedElapsed
        }
        return pausedElapsed + now.timeIntervalSince(startedAt)
    }

    func remainingOrElapsedSeconds(at now: Date) -> Int {
        let elapsedSeconds = Int(elapsed(at: now))

        switch mode {
        case .countdown:
            let remaining = configuredSeconds - elapsedSeconds
            if remaining <= 0 {
                state = .completed
                return 0
            }
            return remaining
        case .countUp:
            if elapsedSeconds >= configuredSeconds {
                state = .completed
                return configuredSeconds
            }
            return elapsedSeconds
        }
    }

    func start(at now: Date) {
        state = .running
        startedAt = now
    }

    func pause(at now: Date) {
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
    }

    /// 초 단위 값을 `HH:MM:SS` 문자열로 표시한다. View 밖에서 테스트할 수 있도록 순수 함수로 둔다.
    /// 화면에 표시 가능한 최대치(23:59:59)로 clamp한 뒤 포맷한다. 호출부가 항상 유효한
    /// 범위의 값을 넘겨주지만, 그 보장이 깨지는 경우(데이터 임포트, 마이그레이션 등)에도
    /// 항상 유효한 형식의 문자열만 보여주기 위한 사전 안전장치다(이슈 #34).
    static func formattedClock(seconds: Int) -> String {
        let clamped = max(0, min(seconds, 86399))
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let secs = clamped % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}

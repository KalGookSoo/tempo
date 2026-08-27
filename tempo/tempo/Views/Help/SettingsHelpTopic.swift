import Foundation

/// 설정 탭 "도움말"에서 보여줄 주제 하나. `id`는 `SettingsRoute.helpDetail(id:)`가 쓴다.
/// 이름이 `HelpTopic`이 아니라 `SettingsHelpTopic`인 이유: 인터벌 탭의
/// `IntervalHelpView.swift`가 이미 좁은 범위의(Tabata/EMOM/FGB 도움말) `HelpTopic`을
/// 파일 스코프로 선언하고 있어 이름이 겹친다.
struct SettingsHelpTopic: Identifiable {
    let id: String
    let title: String
    let summary: String
    /// 상세 화면에 순서대로 보여줄 문단.
    let paragraphs: [String]
}

/// `docs/use-cases/*.md`가 원본(source of truth)이고, 여기 콘텐츠는 그 "목적"/"기본 흐름"을
/// 화면에 맞게 요약·각색한 것이다. 기능이 바뀌면 문서와 이 목록을 같이 갱신한다.
/// 인터벌 프로그램을 직접 만드는 세부 방법은 다루지 않는다 — 인터벌 탭 자체 도움말
/// (`IntervalHelpView`/`IntervalHelpDetailView`)의 역할이라 중복을 피한다.
enum HelpLibrary {
    static let topics: [SettingsHelpTopic] = [
        SettingsHelpTopic(
            id: "timer",
            title: "타이머",
            summary: "카운트다운과 카운트업을 토글로 오가며 실행합니다.",
            paragraphs: [
                "타이머는 카운트다운 모드로 열리며, 화면 우측 상단 토글로 언제든 카운트업으로 전환할 수 있습니다.",
                "시간·분·초는 드래그 picker로 설정하고, 레이블과 종료 시 사운드도 지정할 수 있습니다.",
                "시작하면 입력이 잠기고 설정한 모드로 실행됩니다. 실행 중에는 일시정지·재개·리셋이 가능하고, 종료되면 사운드·진동·알림으로 알려줍니다.",
            ]
        ),
        SettingsHelpTopic(
            id: "stopwatch",
            title: "스톱워치",
            summary: "종료 시간 없이 경과 시간을 재고, 랩을 기록합니다.",
            paragraphs: [
                "시작을 누르면 00:00.00부터 시간이 올라갑니다. 준비 카운트다운이나 알림 큐 없이 바로 실행됩니다.",
                "실행 중 좌측 버튼으로 랩을 기록하면 목록 맨 위에 랩 번호·구간 시간·누적 시간이 함께 쌓입니다.",
                "정지 후 재개하거나 리셋할 수 있고, 리셋하면 경과 시간과 랩 목록이 함께 초기화됩니다.",
            ]
        ),
        SettingsHelpTopic(
            id: "interval-timing",
            title: "인터벌 타이밍",
            summary: "운동·휴식 구간을 라운드 단위로 반복 실행합니다.",
            paragraphs: [
                "운동/휴식 시간과 라운드 수를 입력해 최대 9개 세트, 99라운드까지 구성할 수 있습니다. 휴식이 00:00이면 해당 구간은 건너뜁니다.",
                "시작하면 필요 시 준비 카운트다운을 거쳐 운동·휴식 구간이 순서대로 반복되고, 마지막 라운드가 끝나면 종료됩니다.",
                "인터벌 프로그램을 직접 만드는 방법은 인터벌 탭의 \"새 프로그램\" 화면에서 직접 입력해보며 확인할 수 있습니다.",
            ]
        ),
        SettingsHelpTopic(
            id: "preset-management",
            title: "프리셋 관리",
            summary: "기본 프리셋을 바로 실행하거나, 내 프리셋을 만들고 관리합니다.",
            paragraphs: [
                "Tabata, FGB, EMOM 같은 기본 프리셋은 목록에서 바로 실행할 수 있고 삭제할 수 없습니다.",
                "새 프리셋을 만들려면 이름과 인터벌 세트·라운드·알림 큐를 설정하고 저장하면 목록에 추가됩니다.",
                "기본 프리셋은 복제해서 내 프리셋으로 바꿀 수 있고, 내 프리셋은 이름 변경·편집·복제·삭제가 자유롭습니다.",
            ]
        ),
        SettingsHelpTopic(
            id: "notification-cues",
            title: "알림 큐",
            summary: "타이머 상태 변화를 소리·진동·녹음 음성으로 알려줍니다.",
            paragraphs: [
                "알림 방식은 없음/사운드/진동/사운드+진동 중에서 고르고, 시작 전 알림 시점(없음·1·3·5·10초)도 설정할 수 있습니다.",
                "준비·운동 시작·휴식 시작·구간 종료·라운드 종료·전체 종료 같은 이벤트마다 알림 방식을 따로 지정할 수 있습니다.",
                "기본 제공 사운드 외에 설정 > 녹음한 사운드에서 직접 녹음한 음성도 알림 큐로 쓸 수 있습니다.",
            ]
        ),
        SettingsHelpTopic(
            id: "mirrored-timer-display",
            title: "미러링 실행 화면",
            summary: "화면을 외부 디스플레이에 미러링해 멀리서도 타이머를 확인합니다.",
            paragraphs: [
                "실행 화면은 시간 숫자와 현재 상태(준비/운동/휴식 등)를 가장 크게 보여주도록 만들어져 있습니다.",
                "화면을 TV나 모니터에 미러링하면 컨트롤 버튼에 방해받지 않고 멀리서도 크게 볼 수 있습니다.",
                "세로·가로 화면을 모두 지원하며, 미러링 중에도 기기에서 시작·일시정지·재개·리셋을 그대로 조작할 수 있습니다.",
            ]
        ),
    ]

    static func topic(id: String) -> SettingsHelpTopic? {
        topics.first { $0.id == id }
    }
}

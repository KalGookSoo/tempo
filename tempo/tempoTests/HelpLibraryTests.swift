@testable import tempo
import Testing

/// 이슈 #10: `docs/use-cases/`의 6개 유즈케이스가 빠짐없이, 중복 없이 라이브러리에
/// 등록돼 있는지 검증하는 회귀 테스트.
@Suite("HelpLibrary")
struct HelpLibraryTests {
    @Test("6개 주제가 docs/use-cases의 6개 유즈케이스와 1:1로 대응한다")
    func hasSixTopicsMatchingUseCases() {
        let ids = Set(HelpLibrary.topics.map(\.id))

        #expect(HelpLibrary.topics.count == 6)
        #expect(ids == [
            "timer",
            "stopwatch",
            "interval-timing",
            "preset-management",
            "notification-cues",
            "mirrored-timer-display",
        ])
    }

    @Test("모든 주제는 제목/요약/본문 문단을 빠짐없이 갖는다")
    func everyTopicHasContent() {
        for topic in HelpLibrary.topics {
            #expect(!topic.title.isEmpty)
            #expect(!topic.summary.isEmpty)
            #expect(!topic.paragraphs.isEmpty)
        }
    }

    @Test("id로 주제를 찾을 수 있고, 없는 id는 nil을 반환한다")
    func findsTopicByID() {
        #expect(HelpLibrary.topic(id: "timer")?.title == "타이머")
        #expect(HelpLibrary.topic(id: "존재하지-않음") == nil)
    }
}

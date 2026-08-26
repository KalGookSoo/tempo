//
//  IntervalHelpView.swift
//  tempo
//

import SwiftUI

/// `.intervalHelp` 화면. Tabata, EMOM, FGB 스타일, 사용자 커스텀 프로그램명을 목록으로 보여준다.
/// docs/navigation-structure.md "도움말 `.intervalHelp`" 참고.
private struct HelpTopic: Identifiable {
    let id: String
    let title: String
}

private let helpTopics: [HelpTopic] = [
    HelpTopic(id: "tabata", title: "Tabata"),
    HelpTopic(id: "emom", title: "EMOM"),
    HelpTopic(id: "fgb", title: "FGB 스타일"),
    HelpTopic(id: "custom", title: "사용자 커스텀 인터벌"),
]

struct IntervalHelpView: View {
    var body: some View {
        List(helpTopics) { topic in
            NavigationLink(value: Route.intervalHelpDetail(id: topic.id)) {
                Text(topic.title)
            }
        }
        .navigationTitle("도움말")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        IntervalHelpView()
    }
}

import SwiftUI

/// `.helpDetail(id:)` 화면. `HelpLibrary`에서 주제를 찾아 문단을 순서대로 보여준다.
struct SettingsHelpDetailView: View {
    let id: String

    var body: some View {
        Group {
            if let topic = HelpLibrary.topic(id: id) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(topic.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                            Text(LocalizedStringKey(paragraph))
                        }
                    }
                    .padding()
                }
                .navigationTitle(LocalizedStringKey(topic.title))
            } else {
                ContentUnavailableView {
                    Label("도움말", systemImage: "questionmark.circle")
                } description: {
                    Text("'\(id)' 주제를 찾을 수 없습니다.")
                }
                .navigationTitle("도움말")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsHelpDetailView(id: "timer")
    }
}

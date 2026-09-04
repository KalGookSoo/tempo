import SwiftUI

/// `.help` 화면. 앱 전체 기능 개요를 주제별 목록으로 보여준다. `docs/use-cases/*.md`가
/// 원본이고, 콘텐츠는 `HelpLibrary`에서 관리한다.
struct SettingsHelpView: View {
    var body: some View {
        List(HelpLibrary.topics) { topic in
            NavigationLink(value: SettingsRoute.helpDetail(id: topic.id)) {
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey(topic.title))
                    Text(LocalizedStringKey(topic.summary))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("도움말")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsHelpView()
    }
}

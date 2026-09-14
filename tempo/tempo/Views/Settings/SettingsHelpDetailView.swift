import SwiftUI
import UIKit

/// `.helpDetail(id:)` 화면. `HelpLibrary`에서 주제를 찾아 스크린샷(있으면)과 문단을
/// 순서대로 보여준다.
struct SettingsHelpDetailView: View {
    let id: String

    var body: some View {
        Group {
            if let topic = HelpLibrary.topic(id: id) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let image = Self.screenshot(for: topic.id) {
                            image
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
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

    /// `Resources/HelpImages/`에 주제 id와 같은 이름(예: `timer.jpg`)으로 넣어둔 스크린샷을
    /// 찾는다. 애셋 카탈로그가 아니라 일반 번들 리소스라(`Resources/Sounds/`와 같은 방식),
    /// `Image(_:)`가 아니라 `Bundle.main.url(forResource:withExtension:)`로 찾아야 한다.
    /// 없으면 nil — 이미지 없는 주제도 그냥 문단만 보여주면 된다.
    private static func screenshot(for topicID: String) -> Image? {
        guard let url = Bundle.main.url(forResource: topicID, withExtension: "jpg"),
              let uiImage = UIImage(contentsOfFile: url.path)
        else { return nil }
        return Image(uiImage: uiImage)
    }
}

#Preview {
    NavigationStack {
        SettingsHelpDetailView(id: "timer")
    }
}

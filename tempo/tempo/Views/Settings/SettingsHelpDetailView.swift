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
                    VStack(alignment: .leading, spacing: 20) {
                        if let image = Self.screenshot(for: topic.id) {
                            // 실제 화면이 아니라 스크린샷이라는 걸 한눈에 구분할 수 있도록
                            // 얇은 테두리를 두른다(장식이 아니라 이미지/실제 화면 구분용).
                            image
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color(.separator), lineWidth: 1)
                                )
                        }

                        Text(LocalizedStringKey(topic.summary))
                            .font(.title3.bold())

                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(topic.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                                Text(LocalizedStringKey(paragraph))
                                    .foregroundStyle(.secondary)
                            }
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

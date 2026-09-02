import SwiftUI

/// `.version` 화면. 앱 버전/빌드 번호를 `Bundle.main`에서 읽어 그대로 보여준다.
struct SettingsVersionView: View {
    private var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }

    var body: some View {
        List {
            LabeledContent("버전", value: shortVersion)
            LabeledContent("빌드", value: buildNumber)
        }
        .constrainedWidth()
        .navigationTitle("버전 정보")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsVersionView()
    }
}

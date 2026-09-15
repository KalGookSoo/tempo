import SwiftUI
import UIKit

/// 설정 탭의 루트 화면. moov의 "관리" 탭처럼 도움말/온보딩/버전 정보를 모아 보여준다.
struct SettingsHomeView: View {
    var body: some View {
        List {
            NavigationLink(value: SettingsRoute.cue) {
                Label("알림 큐", systemImage: "bell.badge")
            }
            NavigationLink(value: SettingsRoute.recordings) {
                Label("녹음한 사운드", systemImage: "mic")
            }
            NavigationLink(value: SettingsRoute.help) {
                Label("도움말", systemImage: "questionmark.circle")
            }
            NavigationLink(value: SettingsRoute.onboarding) {
                Label("사용법 다시 보기", systemImage: "sparkles")
            }
            Link(destination: Self.contactURL) {
                Label("문의하기", systemImage: "envelope")
            }
            NavigationLink(value: SettingsRoute.version) {
                Label("버전 정보", systemImage: "info.circle")
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// 일반 사용자는 Xcode 콘솔을 볼 수 없어서(이슈 #89), 배포 후엔 이 경로가 유일한
    /// 버그 신고 통로다. 개인정보처리방침(#68)/스토어 메타데이터(#69)에서 이미 "문의는
    /// GitHub Issues로"라고 안내해둔 것과 같은 채널로 통일한다 — 별도 지원 이메일을 새로
    /// 정하는 대신, 기존에 정한 채널 그대로 쓴다. 제목/본문에 기기·OS·앱 버전을
    /// 미리 채워서 GitHub의 "새 이슈" 작성 화면으로 연결한다.
    private static var contactURL: URL {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        let body = """
        (문제 내용을 자유롭게 적어주세요)

        ---
        앱 버전: \(version) (\(build))
        기기: \(UIDevice.current.model)
        iOS 버전: \(UIDevice.current.systemVersion)
        """
        var components = URLComponents(string: "https://github.com/KalGookSoo/tempo/issues/new")!
        components.queryItems = [
            URLQueryItem(name: "title", value: "[버그] "),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url!
    }
}

#Preview {
    NavigationStack {
        SettingsHomeView()
    }
}

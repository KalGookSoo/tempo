import SwiftData
import SwiftUI

@main
struct tempoApp: App {
    @State private var intervalRouter = Router()
    @State private var settingsRouter = Router()
    @State private var showsOnboarding = false
    @State private var selectedTab: AppTab = .timer
    @State private var notificationDelegate = NotificationDelegate()
    private let modelContainer = SharedModelContainer.make()

    enum AppTab: Hashable {
        case timer, stopwatch, interval, settings
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                Tab("타이머", systemImage: "timer", value: AppTab.timer) {
                    TimerView()
                }
                Tab("스톱워치", systemImage: "stopwatch", value: AppTab.stopwatch) {
                    StopwatchView()
                }
                Tab("인터벌", systemImage: "repeat", value: AppTab.interval) {
                    NavigationStack(path: $intervalRouter.path) {
                        IntervalProgramsView()
                            .navigationDestination(for: IntervalRoute.self, destination: intervalDestination(for:))
                    }
                    .environment(intervalRouter)
                }
                Tab("설정", systemImage: "gearshape.fill", value: AppTab.settings) {
                    NavigationStack(path: $settingsRouter.path) {
                        SettingsHomeView()
                            .navigationDestination(for: SettingsRoute.self, destination: settingsDestination(for:))
                    }
                    .environment(settingsRouter)
                }
            }
            // 넓은 화면(아이패드 가로 등)에서 콘텐츠가 화면 폭 그대로 늘어나지 않도록 앱
            // 전체를 태블릿 세로 폭으로 제한한다. 타이머/스톱워치/인터벌 실행 화면도 지금은
            // 함께 제한된다 — 자식 뷰가 부모(TabView)보다 넓어질 수 없어 modifier로 자동
            // 예외 처리할 수 없었다(이슈 #47). 대신 나중에 이 화면들에 수동 "전체 화면" 버튼을
            // 추가해 사용자가 직접 전환하게 할 계획이다. 이슈 #45, #47 참고.
            .constrainedWidth()
            .fullScreenCover(isPresented: $showsOnboarding) {
                OnboardingView(onComplete: completeOnboarding)
            }
            .task {
                checkOnboarding()
                CueTriggerPlayer.prewarmAudioSession()
                UNUserNotificationCenter.current().delegate = notificationDelegate
                notificationDelegate.onTapTimer = { selectedTab = .timer }
                notificationDelegate.onTapInterval = { selectedTab = .interval }
            }
        }
        .modelContainer(modelContainer)
    }

    /// 최초 실행이면(또는 아직 완료/건너뛰지 않았으면) 온보딩을 띄운다.
    private func checkOnboarding() {
        guard let settings = try? SettingsRepository(modelContext: modelContainer.mainContext).find() else { return }
        showsOnboarding = !settings.hasCompletedOnboarding
    }

    private func completeOnboarding() {
        try? SettingsRepository(modelContext: modelContainer.mainContext).completeOnboarding()
        showsOnboarding = false
    }

    @ViewBuilder
    private func intervalDestination(for route: IntervalRoute) -> some View {
        switch route {
        case .new:
            IntervalNewView()
        case .programs:
            IntervalProgramsView()
        case let .programDetail(id):
            IntervalProgramDetailView(id: id)
        case let .programEdit(id):
            IntervalProgramEditView(id: id)
        case let .run(programID):
            IntervalRunView(programID: programID)
        }
    }

    @ViewBuilder
    private func settingsDestination(for route: SettingsRoute) -> some View {
        switch route {
        case .help:
            SettingsHelpView()
        case let .helpDetail(id):
            SettingsHelpDetailView(id: id)
        case .onboarding:
            SettingsOnboardingView()
        case .version:
            SettingsVersionView()
        case .cue:
            SettingsCueView()
        case .recordings:
            SettingsRecordingsView()
        }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var onTapTimer: (() -> Void)?
    var onTapInterval: (() -> Void)?

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.notification.request.identifier {
        case "timer.end":
            onTapTimer?()
        case "interval.end":
            onTapInterval?()
        default:
            break
        }
        completionHandler()
    }
}

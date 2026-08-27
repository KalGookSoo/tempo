//
//  tempoApp.swift
//  tempo
//
//  Created by doyevskyi on 8/12/26.
//

import SwiftData
import SwiftUI

@main
struct tempoApp: App {
    @State private var intervalRouter = Router()
    @State private var settingsRouter = Router()
    @State private var showsOnboarding = false
    private let modelContainer = SharedModelContainer.make()

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("타이머", systemImage: "timer") {
                    TimerView()
                }
                Tab("스톱워치", systemImage: "stopwatch") {
                    StopwatchView()
                }
                Tab("인터벌", systemImage: "repeat") {
                    NavigationStack(path: $intervalRouter.path) {
                        IntervalHomeView()
                            .navigationDestination(for: IntervalRoute.self, destination: intervalDestination(for:))
                    }
                    .environment(intervalRouter)
                }
                Tab("설정", systemImage: "gearshape.fill") {
                    NavigationStack(path: $settingsRouter.path) {
                        SettingsHomeView()
                            .navigationDestination(for: SettingsRoute.self, destination: settingsDestination(for:))
                    }
                    .environment(settingsRouter)
                }
            }
            .fullScreenCover(isPresented: $showsOnboarding) {
                OnboardingView(onComplete: completeOnboarding)
            }
            .task {
                checkOnboarding()
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
        case .help:
            IntervalHelpView()
        case let .helpDetail(id):
            IntervalHelpDetailView(id: id)
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

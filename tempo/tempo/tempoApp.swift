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
        }
        .modelContainer(modelContainer)
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
        case .onboarding:
            SettingsOnboardingView()
        case .version:
            SettingsVersionView()
        case .cue:
            SettingsCueView()
        }
    }
}

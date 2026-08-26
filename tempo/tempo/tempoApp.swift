//
//  tempoApp.swift
//  tempo
//
//  Created by doyevskyi on 8/12/26.
//

import SwiftUI

@main
struct tempoApp: App {
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HomeView()
                    .navigationDestination(for: Route.self, destination: destination(for:))
            }
            .environment(router)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .timer:
            TimerView()
        case .stopwatch:
            StopwatchView()
        case .interval:
            IntervalHomeView()
        case .intervalNew:
            IntervalNewView()
        case .intervalPrograms:
            IntervalProgramsView()
        case .intervalProgramDetail(let id):
            IntervalProgramDetailView(id: id)
        case .intervalProgramEdit(let id):
            IntervalProgramEditView(id: id)
        case .intervalHelp:
            IntervalHelpView()
        case .intervalHelpDetail(let id):
            IntervalHelpDetailView(id: id)
        case .intervalRun(let programID):
            IntervalRunView(programID: programID)
        }
    }
}

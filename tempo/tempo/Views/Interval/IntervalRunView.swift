//
//  IntervalRunView.swift
//  tempo
//

import SwiftData
import SwiftUI

/// `.run(programID:)` 화면. `programID`로 실제 `TimerPreset`을 조회해서 `IntervalRunner`를
/// 만들고, 화면에 들어오는 즉시 실행을 시작한다("실행" 액션은 프로그램 상세 화면에서 이미
/// 눌렸으므로 이 화면은 대기 없이 바로 진행한다). docs/navigation-structure.md
/// "인터벌 실행 `.intervalRun(programID:)`" 참고.
struct IntervalRunView: View {
    let programID: String

    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 64

    @State private var runner: IntervalRunner?
    @State private var presetNotFound = false

    var body: some View {
        Group {
            if let runner {
                runningContent(runner: runner)
            } else if presetNotFound {
                ContentUnavailableView {
                    Label("프로그램을 찾을 수 없음", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("프로그램 ID: \(programID)")
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("인터벌 실행")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .task {
            loadAndStart()
        }
    }

    private func runningContent(runner: IntervalRunner) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let progress = runner.currentProgress(at: context.date)

            VStack(spacing: 16) {
                if let progress {
                    if progress.step.round > 0 {
                        Text("라운드 \(progress.step.round) / \(progress.step.totalRounds)")
                            .font(.headline)
                    }

                    Text(progress.step.label)
                        .font(.title)

                    Text(IntervalRunner.formattedClock(seconds: progress.remainingSeconds))
                        .font(.system(size: timerFontSize, weight: .bold, design: .monospaced))
                } else {
                    Text("완료")
                        .font(.system(size: timerFontSize, weight: .bold, design: .monospaced))
                }

                HStack {
                    Button("완료") {
                        router.popToRoot()
                    }
                    .buttonStyle(.bordered)

                    if runner.state == .running || runner.state == .preparing {
                        Button("일시정지") {
                            runner.pause(at: .now)
                        }
                        .buttonStyle(.borderedProminent)
                    } else if runner.state == .paused {
                        Button("재개") {
                            runner.resume(at: .now)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Button("설정 수정") {
                        router.push(IntervalRoute.programEdit(id: programID))
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func loadAndStart() {
        guard runner == nil, !presetNotFound else { return }

        guard
            let id = UUID(uuidString: programID),
            let preset = try? PresetRepository(modelContext: modelContext).findPreset(id: id)
        else {
            presetNotFound = true
            return
        }

        let newRunner = IntervalRunner(config: preset.config)
        newRunner.start(at: .now)
        runner = newRunner
    }
}

#Preview {
    NavigationStack {
        IntervalRunView(programID: "preview")
    }
    .environment(Router())
}

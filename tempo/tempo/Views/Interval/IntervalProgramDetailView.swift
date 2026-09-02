import SwiftData
import SwiftUI

/// `.programDetail(id:)` 화면. `id`로 실제 `TimerPreset`을 조회해서 이름/구성을 보여주고,
/// 실행/복제/수정/삭제를 제공한다. 수정은 `.programEdit(id:)`(`IntervalProgramEditView`)
/// 별도 화면으로 이동해서 처리한다 — 상세/수정을 한 화면 안에서 조건 분기로 전환하던
/// 방식(#33)에서 다시 분리한 배경은 이슈 #46. docs/navigation-structure.md
/// "프로그램 상세 `.programDetail(id:)`" 참고.
struct IntervalProgramDetailView: View {
    let id: String

    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    @State private var preset: TimerPreset?
    @State private var presetNotFound = false
    @State private var errorMessage: String?
    @State private var isDeleteConfirmationPresented: Bool = false

    var body: some View {
        content
            .navigationTitle("프로그램 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert(
                "실패했습니다",
                isPresented: Binding(get: { errorMessage != nil }, set: {
                    if !$0 {
                        errorMessage = nil
                    }
                }),
                actions: { Button("확인") {} },
                message: { Text(errorMessage ?? "") }
            )
            .alert(
                "프로그램을 삭제할까요?",
                isPresented: $isDeleteConfirmationPresented
            ) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    delete()
                }
            } message: {
                Text("\(preset?.name ?? "") 프로그램을 삭제하면 되돌릴 수 없습니다.")
            }
            .task {
                load()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let preset {
            detailList(for: preset)
        } else if presetNotFound {
            ContentUnavailableView {
                Label("프로그램을 찾을 수 없음", systemImage: "exclamationmark.triangle")
            } description: {
                Text("프로그램 ID: \(id)")
            }
        } else {
            ProgressView()
        }
    }

    private func detailList(for preset: TimerPreset) -> some View {
        List {
            Section {
                LabeledContent("이름", value: preset.name)
            }

            Section("구성") {
                LabeledContent("라운드", value: "\(preset.config.rounds)")
                LabeledContent("준비 시간", value: IntervalRunner.formattedClock(seconds: preset.config.prepareSeconds))
                ForEach(Array(EditableIntervalSet.pairs(from: preset.config.segments).enumerated()), id: \.offset) { index, set in
                    LabeledContent(
                        "세트 \(index + 1)",
                        value: "운동 \(IntervalRunner.formattedClock(seconds: set.workSeconds)) · 휴식 \(IntervalRunner.formattedClock(seconds: set.restSeconds))"
                    )
                }
            }

            Section {
                NavigationLink(value: IntervalRoute.run(programID: id)) {
                    Label("실행", systemImage: "play.fill")
                }

                Button {
                    duplicate()
                } label: {
                    Label("복제", systemImage: "plus.square.on.square")
                }

                Button(role: .destructive) {
                    isDeleteConfirmationPresented = true
                } label: {
                    Label("삭제", systemImage: "trash")
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if preset != nil {
            ToolbarItem(placement: .primaryAction) {
                Button("수정") { router.push(IntervalRoute.programEdit(id: id)) }
            }
        }
    }

    private func load() {
        guard preset == nil, !presetNotFound else { return }

        guard
            let uuid = UUID(uuidString: id),
            let found = try? PresetRepository(modelContext: modelContext).findPreset(id: uuid)
        else {
            presetNotFound = true
            return
        }

        preset = found
    }

    private func duplicate() {
        guard let preset else { return }
        do {
            let copy = try PresetRepository(modelContext: modelContext).duplicate(preset)
            router.push(IntervalRoute.programDetail(id: copy.id.uuidString))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete() {
        guard let preset else { return }
        do {
            try PresetRepository(modelContext: modelContext).delete(preset)
            router.pop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        IntervalProgramDetailView(id: "preview")
    }
    .environment(Router())
}

import SwiftData
import SwiftUI

/// `.programEdit(id:)` 화면. `id`로 실제 `TimerPreset`을 불러와 `IntervalNewView`와 같은
/// 입력 폼(`IntervalConfigFormFields`)으로 수정한다. 저장/뒤로가기 모두 상세 화면으로
/// 복귀한다(이미 스택에 있으므로 pop). docs/navigation-structure.md "프로그램 수정
/// `.programEdit(id:)`" 참고. `IntervalProgramDetailView`와 화면을 분리한 배경은 이슈 #46.
struct IntervalProgramEditView: View {
    let id: String

    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    @State private var preset: TimerPreset?
    @State private var presetNotFound = false
    @State private var name = ""
    @State private var rounds = 1
    @State private var prepareSeconds = 0
    @State private var sets: [EditableIntervalSet] = []
    @State private var errorMessage: String?
    @State private var timeTarget: IntervalConfigFormFields.SetTimeTarget?
    // 화면 진입 직후(NavigationStack 푸시 전환 애니메이션 도중)엔 세트 시간 팝업을
    // 못 열게 막는다. `.sheet`/`NavigationTransitionGate`를 Form 안(Section 하나)에
    // 붙이면 그 Section이 속한 List 셀 안에 갇혀 실제 화면 전환의 transitionCoordinator를
    // 못 읽어와, 전환 도중 탭했을 때 팝업이 열렸다 바로 닫히는(iPad에서는 "이미 다른
    // 화면을 표시 중" 콘솔 에러까지 찍히는) 문제가 있었다. 그래서 화면 최상위에 붙인다.
    @State private var canOpenTimePicker = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !sets.isEmpty
    }

    var body: some View {
        Group {
            if preset != nil {
                Form {
                    IntervalConfigFormFields(
                        name: $name,
                        rounds: $rounds,
                        prepareSeconds: $prepareSeconds,
                        sets: $sets,
                        timeTarget: $timeTarget,
                        canOpenTimePicker: canOpenTimePicker
                    )
                }
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
        .navigationTitle("프로그램 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") { save() }
                    .disabled(!isValid)
            }
        }
        .alert(
            "저장하지 못했습니다",
            isPresented: Binding(get: { errorMessage != nil }, set: {
                if !$0 {
                    errorMessage = nil
                }
            }),
            actions: { Button("확인") {} },
            message: { Text(errorMessage ?? "") }
        )
        .background(NavigationTransitionGate { canOpenTimePicker = true })
        .sheet(item: $timeTarget) { target in
            IntervalSetTimePickerView(title: target.title, range: target.range, seconds: target.seconds)
        }
        .task {
            load()
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
        name = found.name
        rounds = found.config.rounds
        prepareSeconds = found.config.prepareSeconds
        sets = EditableIntervalSet.pairs(from: found.config.segments)
    }

    private func save() {
        guard let preset else { return }

        let config = IntervalConfig(
            rounds: rounds,
            prepareSeconds: prepareSeconds,
            segments: EditableIntervalSet.segments(from: sets)
        )

        do {
            try PresetRepository(modelContext: modelContext).update(preset, name: name, config: config)
            router.pop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        IntervalProgramEditView(id: "preview")
    }
    .environment(Router())
}

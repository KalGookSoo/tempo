import SwiftUI

/// `.programEdit(id:)` 화면. `id`로 실제 `TimerPreset`을 불러와 `IntervalNewView`와 같은
/// 입력 폼(`IntervalConfigFormFields`)으로 수정한다. 기본 프리셋은 이 화면에 도달하지 않는
/// 게 정상이지만(상세 화면에서 커스텀 프리셋에만 "수정" 버튼을 노출), 혹시 도달해도
/// `PresetRepository.update`가 `cannotModifyDefaultPreset`을 던져 안전하게 막는다.
/// 저장/취소 모두 상세 화면으로 복귀한다(이미 스택에 있으므로 pop). docs/navigation-structure.md
/// "프로그램 수정 `.intervalProgramEdit(id:)`" 참고.
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

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !sets.isEmpty
    }

    var body: some View {
        Group {
            if preset != nil {
                Form {
                    IntervalConfigFormFields(name: $name, rounds: $rounds, prepareSeconds: $prepareSeconds, sets: $sets)
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

import SwiftData
import SwiftUI

/// `.new` 화면. 이름/구간 구성/라운드를 입력받아 `PresetRepository.createCustomPreset`으로
/// 저장하고, 새로 생긴 프리셋의 상세 화면으로 이동한다. 알림 큐 설정은 별도 이슈(#15)에서
/// 다룬다. docs/navigation-structure.md "새 프로그램 `.intervalNew`" 참고.
struct IntervalNewView: View {
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var rounds = 8
    @State private var prepareSeconds = 10
    @State private var sets: [EditableIntervalSet] = [EditableIntervalSet(workSeconds: 20, restSeconds: 10)]
    @State private var errorMessage: String?
    @State private var timeTarget: IntervalConfigFormFields.SetTimeTarget?
    // 화면 전환 애니메이션 도중엔 세트 시간 팝업을 못 열게 막는다.
    // IntervalProgramEditView.swift의 같은 프로퍼티 주석 참고.
    @State private var canOpenTimePicker = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !sets.isEmpty
    }

    var body: some View {
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
        .navigationTitle("새 프로그램")
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
    }

    private func save() {
        let config = IntervalConfig(
            rounds: rounds,
            prepareSeconds: prepareSeconds,
            segments: EditableIntervalSet.segments(from: sets)
        )

        do {
            let preset = try PresetRepository(modelContext: modelContext).createCustomPreset(name: name, config: config)
            router.pop()
            router.push(IntervalRoute.programDetail(id: preset.id.uuidString))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        IntervalNewView()
    }
    .environment(Router())
}

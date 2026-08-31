import SwiftUI

/// `IntervalConfig.segments`는 [운동, 휴식, 운동, 휴식, ...] 순서로 이어지는 평평한 배열이다.
/// 화면에서는 "세트(운동+휴식 한 쌍)" 단위로 편집하는 게 자연스러워서, 편집 중에만 쓰는 쌍
/// 단위 타입을 따로 둔다. `IntervalNewView`/`IntervalProgramEditView`가 공유한다.
struct EditableIntervalSet: Identifiable, Equatable {
    let id = UUID()
    var workSeconds: Int
    var restSeconds: Int

    static func pairs(from segments: [IntervalSegment]) -> [EditableIntervalSet] {
        stride(from: 0, to: segments.count, by: 2).compactMap { index in
            guard index + 1 < segments.count else { return nil }
            return EditableIntervalSet(workSeconds: segments[index].seconds, restSeconds: segments[index + 1].seconds)
        }
    }

    static func segments(from sets: [EditableIntervalSet]) -> [IntervalSegment] {
        sets.flatMap {
            [IntervalSegment(type: .work, seconds: $0.workSeconds), IntervalSegment(type: .rest, seconds: $0.restSeconds)]
        }
    }
}

/// 이름/준비 시간/라운드/인터벌 세트 입력 폼. `Form { }` 안에서 쓰도록 `Section`들을
/// 그대로 반환한다 (자체 `Form`을 갖지 않음). `IntervalNewView`와 `IntervalProgramEditView`가
/// 공유한다 — docs/navigation-structure.md에서 "`.new`와 동일한 단계형 흐름을 재사용"한다고
/// 정해둔 부분.
struct IntervalConfigFormFields: View {
    @Binding var name: String
    @Binding var rounds: Int
    @Binding var prepareSeconds: Int
    @Binding var sets: [EditableIntervalSet]

    var body: some View {
        Section("이름") {
            TextField("이름", text: $name)
        }

        Section("준비 시간") {
            Stepper(
                "준비 \(IntervalRunner.formattedClock(seconds: prepareSeconds))",
                value: $prepareSeconds,
                in: 10 ... 60,
                step: 5
            )
        }

        Section("라운드") {
            Stepper("\(rounds)라운드", value: $rounds, in: 1 ... 99)
        }

        Section("인터벌 세트 (최대 9개)") {
            ForEach($sets) { $set in
                VStack(alignment: .leading, spacing: 16) {
                    Stepper(
                        "운동 \(IntervalRunner.formattedClock(seconds: set.workSeconds))",
                        value: $set.workSeconds,
                        in: 5 ... 5999,
                        step: 5
                    )
                    Stepper(
                        "휴식 \(IntervalRunner.formattedClock(seconds: set.restSeconds))",
                        value: $set.restSeconds,
                        in: 0 ... 5999,
                        step: 5
                    )
                }
            }
            .onDelete { offsets in
                sets.remove(atOffsets: offsets)
            }

            if sets.count < 9 {
                Button {
                    sets.append(EditableIntervalSet(workSeconds: 20, restSeconds: 10))
                } label: {
                    Label("세트 추가", systemImage: "plus")
                }
            }
        }
    }
}

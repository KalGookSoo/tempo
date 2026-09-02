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

    @FocusState private var focusedField: Field?
    @State private var timeTarget: SetTimeTarget?

    private enum Field: Hashable {
        case rounds
    }

    /// 세트의 운동/휴식 시간 팝업을 띄우기 위한 대상. 팝업이 확정되면 `seconds`에 바로
    /// 값이 반영되도록, 해당 세트 필드로 향하는 `Binding`을 그대로 들고 있는다.
    private struct SetTimeTarget: Identifiable {
        let id: String
        let title: String
        let range: ClosedRange<Int>
        let seconds: Binding<Int>
    }

    var body: some View {
        Group {
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
                HStack {
                    Text("라운드")
                    Spacer()
                    TextField(
                        "라운드",
                        value: Binding(get: { rounds }, set: { rounds = min(max($0, 1), 99) }),
                        format: .number
                    )
                    .focused($focusedField, equals: .rounds)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                }
                .contentShape(Rectangle())
                .onTapGesture { focusedField = .rounds }
            }

            Section("인터벌 세트 (최대 9개)") {
                ForEach($sets) { $set in
                    VStack(alignment: .leading, spacing: 16) {
                        timeRow(title: "운동", seconds: $set.workSeconds, range: 5 ... 5999, idSuffix: "work-\(set.id)")
                        timeRow(title: "휴식", seconds: $set.restSeconds, range: 0 ... 5999, idSuffix: "rest-\(set.id)")
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
        .sheet(item: $timeTarget) { target in
            IntervalSetTimePickerView(title: target.title, range: target.range, seconds: target.seconds)
        }
    }

    /// 세트의 운동/휴식 시간 한 줄. 탭하면 텍스트필드 대신 휠 피커 팝업이 뜬다. 이슈 #46 참고.
    ///
    /// `Button`이 아니라 `.onTapGesture`로 구현한다 — 한 세트(운동+휴식)를 `Form` 행 하나로
    /// 묶다 보니(84-89번째 줄) 같은 행 안에 `Button`이 두 개 있게 되는데, `Form`/`List`는
    /// 한 행에 `Button`이 여러 개면 탭을 행 단위로 가로채 항상 같은 버튼으로 몰거나 팝업이
    /// 뜨자마자 닫히는 문제가 있었다. 라운드 필드(66-82번째 줄, 이슈 #44)와 같은 방식으로
    /// 맞춘다.
    private func timeRow(title: String, seconds: Binding<Int>, range: ClosedRange<Int>, idSuffix: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.accentColor)
            Spacer()
            Text(IntervalRunner.formattedClock(seconds: seconds.wrappedValue))
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            timeTarget = SetTimeTarget(id: idSuffix, title: "\(title) 시간", range: range, seconds: seconds)
        }
    }
}

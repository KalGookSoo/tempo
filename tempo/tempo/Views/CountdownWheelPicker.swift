import SwiftUI
import UIKit

/// 분/초가 하나로 합쳐진 카운트다운 피커(최대 99:59). 타이머·인터벌 모두 시(hour) 단위
/// 입력까지는 필요 없다고 판단해 뺐다(이슈 #86) — `TimerEngine`/`IntervalRunner`의
/// `formattedClock`이 보여주는 `MM:SS` 형식과 상한을 그대로 맞췄다. SwiftUI `Picker`를
/// 2개 나란히 놓으면 각 Picker가 선택 하이라이트 바를 따로 그려서(칸이 나뉘어 보임)
/// 네이티브와 다르게 보인다. 그래서 `UIPickerView` 하나를 4개 컴포넌트(분 숫자/"분"/초
/// 숫자/"초")로 직접 구성해, 하나의 공유된 하이라이트 바 안에 표시되게 한다. 이슈 #18 참고.
struct CountdownWheelPicker: UIViewRepresentable {
    @Binding var minutes: Int
    @Binding var seconds: Int

    private static let minuteCount = 100
    private static let secondCount = 60

    /// 0: 분 숫자, 1: "분" 라벨, 2: 초 숫자, 3: "초" 라벨
    private enum Component: Int, CaseIterable {
        case minuteValue, minuteUnit, secondValue, secondUnit
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIView(_ uiView: UIPickerView, context: Context) {
        context.coordinator.parent = self
        // 값이 실제로 다를 때만 selectRow를 호출한다. 매번 무조건 호출하면, 한 컴포넌트를
        // 드르륵 돌리는 도중(아직 didSelectRow가 안 불려 값이 안 바뀐 상태) 다른
        // 컴포넌트를 조작해서 이 뷰가 갱신될 때마다, 돌리고 있는 컴포넌트가 강제로 이전
        // 위치로 스냅되어 돌리던 값이 사라지는 버그가 있었다(이슈 #31).
        if uiView.selectedRow(inComponent: Component.minuteValue.rawValue) != minutes {
            uiView.selectRow(minutes, inComponent: Component.minuteValue.rawValue, animated: false)
        }
        if uiView.selectedRow(inComponent: Component.secondValue.rawValue) != seconds {
            uiView.selectRow(seconds, inComponent: Component.secondValue.rawValue, animated: false)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: CountdownWheelPicker

        init(_ parent: CountdownWheelPicker) {
            self.parent = parent
        }

        func numberOfComponents(in _: UIPickerView) -> Int {
            Component.allCases.count
        }

        func pickerView(_: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch Component(rawValue: component) {
            case .minuteValue: minuteCount
            case .secondValue: secondCount
            default: 1
            }
        }

        func pickerView(_: UIPickerView, widthForComponent component: Int) -> CGFloat {
            switch Component(rawValue: component) {
            case .minuteValue, .secondValue: 50
            default: 44
            }
        }

        func pickerView(
            _: UIPickerView,
            viewForRow row: Int,
            forComponent component: Int,
            reusing view: UIView?
        ) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            label.font = .systemFont(ofSize: 23, weight: .regular)
            // 재사용되는 뷰가 다른 경로로 인터랙션이 켜진 채 재사용될 가능성을 배제하기
            // 위해 명시적으로 꺼둔다(기본값과 같아 효과가 없을 수 있음 — 이슈 #31).
            label.isUserInteractionEnabled = false

            switch Component(rawValue: component) {
            case .minuteValue:
                label.text = "\(row)"
                label.textAlignment = .right
            case .minuteUnit:
                label.text = String(localized: "분")
                label.textAlignment = .left
            case .secondValue:
                label.text = "\(row)"
                label.textAlignment = .right
            case .secondUnit:
                label.text = String(localized: "초")
                label.textAlignment = .left
            case nil:
                break
            }
            return label
        }

        func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch Component(rawValue: component) {
            case .minuteValue: parent.minutes = row
            case .secondValue: parent.seconds = row
            default: break
            }
        }

        private var minuteCount: Int {
            CountdownWheelPicker.minuteCount
        }

        private var secondCount: Int {
            CountdownWheelPicker.secondCount
        }
    }
}

#Preview {
    @Previewable @State var minutes = 15
    @Previewable @State var seconds = 0

    return CountdownWheelPicker(minutes: $minutes, seconds: $seconds)
        .frame(height: 200)
}

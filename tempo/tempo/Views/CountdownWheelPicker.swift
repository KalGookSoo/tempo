import SwiftUI
import UIKit

/// iOS 기본 시계 앱 "타이머" 탭과 동일하게, 시/분/초가 하나로 합쳐진 카운트다운 피커.
/// `UIDatePicker(datePickerMode: .countDownTimer)`는 시/분까지만 지원하고 초 단위가
/// 없어서 쓸 수 없다. SwiftUI `Picker`를 3개 나란히 놓으면 각 Picker가 선택 하이라이트
/// 바를 따로 그려서(칸이 나뉘어 보임) 네이티브와 다르게 보인다. 그래서 `UIPickerView`
/// 하나를 6개 컴포넌트(시 숫자/"시간"/분 숫자/"분"/초 숫자/"초")로 직접 구성해, 하나의
/// 공유된 하이라이트 바 안에 표시되게 한다. 이슈 #18 참고.
struct CountdownWheelPicker: UIViewRepresentable {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    private static let hourCount = 24
    private static let minuteCount = 60
    private static let secondCount = 60

    /// 0: 시 숫자, 1: "시간" 라벨, 2: 분 숫자, 3: "분" 라벨, 4: 초 숫자, 5: "초" 라벨
    private enum Component: Int, CaseIterable {
        case hourValue, hourUnit, minuteValue, minuteUnit, secondValue, secondUnit
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIView(_ uiView: UIPickerView, context: Context) {
        context.coordinator.parent = self
        uiView.selectRow(hours, inComponent: Component.hourValue.rawValue, animated: false)
        uiView.selectRow(minutes, inComponent: Component.minuteValue.rawValue, animated: false)
        uiView.selectRow(seconds, inComponent: Component.secondValue.rawValue, animated: false)
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
            case .hourValue: hourCount
            case .minuteValue: minuteCount
            case .secondValue: secondCount
            default: 1
            }
        }

        func pickerView(_: UIPickerView, widthForComponent component: Int) -> CGFloat {
            switch Component(rawValue: component) {
            case .hourValue, .minuteValue, .secondValue: 50
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

            switch Component(rawValue: component) {
            case .hourValue:
                label.text = "\(row)"
                label.textAlignment = .right
            case .hourUnit:
                label.text = "시간"
                label.textAlignment = .left
            case .minuteValue:
                label.text = "\(row)"
                label.textAlignment = .right
            case .minuteUnit:
                label.text = "분"
                label.textAlignment = .left
            case .secondValue:
                label.text = "\(row)"
                label.textAlignment = .right
            case .secondUnit:
                label.text = "초"
                label.textAlignment = .left
            case nil:
                break
            }
            return label
        }

        func pickerView(_: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch Component(rawValue: component) {
            case .hourValue: parent.hours = row
            case .minuteValue: parent.minutes = row
            case .secondValue: parent.seconds = row
            default: break
            }
        }

        private var hourCount: Int {
            CountdownWheelPicker.hourCount
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
    @Previewable @State var hours = 0
    @Previewable @State var minutes = 15
    @Previewable @State var seconds = 0

    return CountdownWheelPicker(hours: $hours, minutes: $minutes, seconds: $seconds)
        .frame(height: 200)
}

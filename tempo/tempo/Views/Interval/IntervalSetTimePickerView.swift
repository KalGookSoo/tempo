import SwiftUI

/// 인터벌 세트의 운동/휴식 시간을 고르는 팝업. 타이머 화면과 같은 `CountdownWheelPicker`
/// 휠 피커를 재사용해 시/분/초로 고른 뒤 총 초로 환산한다. "완료"를 눌러야 `seconds`에
/// 값이 반영되고 팝업이 닫힌다 — 스와이프로 그냥 닫으면 원래 값 그대로 취소된다.
/// 이슈 #46 참고.
struct IntervalSetTimePickerView: View {
    let title: String
    let range: ClosedRange<Int>
    @Binding var seconds: Int

    @Environment(\.dismiss) private var dismiss
    @State private var hours: Int
    @State private var minutes: Int
    @State private var secondsPart: Int

    init(title: String, range: ClosedRange<Int>, seconds: Binding<Int>) {
        self.title = title
        self.range = range
        _seconds = seconds
        let total = seconds.wrappedValue
        _hours = State(initialValue: total / 3600)
        _minutes = State(initialValue: (total % 3600) / 60)
        _secondsPart = State(initialValue: total % 60)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.headline)

            CountdownWheelPicker(hours: $hours, minutes: $minutes, seconds: $secondsPart)
                .frame(height: 180)

            Button("완료") {
                let total = hours * 3600 + minutes * 60 + secondsPart
                seconds = min(max(total, range.lowerBound), range.upperBound)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .presentationDetents([.medium])
    }
}

#Preview {
    @Previewable @State var seconds = 20

    return Color.clear
        .sheet(isPresented: .constant(true)) {
            IntervalSetTimePickerView(title: "운동 시간", range: 5 ... 5999, seconds: $seconds)
        }
}

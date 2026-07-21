import SwiftUI

struct RetroAnalogClockView: View {
    var diameter: CGFloat = 60

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                clockFace(for: .now)
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    clockFace(for: context.date)
                }
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityLabel("Current time")
        .accessibilityValue(timeAccessibilityLabel(for: .now))
    }

    private func clockFace(for date: Date) -> some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                hourTick(isMajor: index.isMultiple(of: 3), index: index)
            }

            clockHand(length: diameter * 0.24, width: 1.3, angle: hourAngle(for: date))
            clockHand(length: diameter * 0.34, width: 0.9, angle: minuteAngle(for: date))

            Circle()
                .fill(Theme.Colors.textSecondary.opacity(0.55))
                .frame(width: 2, height: 2)
        }
    }

    private func hourTick(isMajor: Bool, index: Int) -> some View {
        let length = diameter * (isMajor ? 0.14 : 0.09)
        return Capsule()
            .fill(Theme.Colors.textSecondary.opacity(isMajor ? 0.55 : 0.32))
            .frame(width: isMajor ? 1.2 : 0.75, height: length)
            .offset(y: -(diameter * 0.5 - length * 0.5))
            .rotationEffect(.degrees(Double(index) * 30))
    }

    private func clockHand(length: CGFloat, width: CGFloat, angle: Angle) -> some View {
        Capsule()
            .fill(Theme.Colors.textSecondary.opacity(0.75))
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(angle)
    }

    private func hourAngle(for date: Date) -> Angle {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = Double(components.hour ?? 0).truncatingRemainder(dividingBy: 12)
        let minute = Double(components.minute ?? 0)
        return .degrees((hour + minute / 60) * 30)
    }

    private func minuteAngle(for date: Date) -> Angle {
        let components = Calendar.current.dateComponents([.minute, .second], from: date)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)
        return .degrees((minute + second / 60) * 6)
    }

    private func timeAccessibilityLabel(for date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}

#Preview {
    RetroAnalogClockView()
        .padding()
        .background(Theme.Colors.backgroundPrimary)
}

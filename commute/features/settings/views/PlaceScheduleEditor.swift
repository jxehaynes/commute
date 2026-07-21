import SwiftUI

struct PlaceScheduleEditor: View {
    @Binding var schedule: PlaceSchedule
    let accent: AccentStyle

    @State private var arriveByDate: Date = .now

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            periodSection
            weekdaySection
            arriveBySection
        }
        .onAppear {
            arriveByDate = Calendar.current.date(from: schedule.arriveBy) ?? .now
        }
        .onChange(of: arriveByDate) { _, date in
            schedule.arriveBy = Calendar.current.dateComponents([.hour, .minute], from: date)
        }
    }

    private var periodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("When you go")
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)

            FlowLayout(spacing: 8) {
                ForEach(DayPeriod.allCases, id: \.self) { period in
                    ScheduleChip(
                        title: period.displayLabel,
                        isSelected: schedule.periods.contains(period),
                        accent: accent
                    ) {
                        togglePeriod(period)
                    }
                }
            }
        }
    }

    private var weekdaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Days")
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Leave empty for every day.")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            FlowLayout(spacing: 8) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    ScheduleChip(
                        title: day.shortLabel,
                        isSelected: schedule.weekdays.contains(day),
                        accent: accent
                    ) {
                        toggleWeekday(day)
                    }
                }
            }
        }
    }

    private var arriveBySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Arrive by")
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)

            DatePicker(
                "Arrive by",
                selection: $arriveByDate,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .font(Theme.Fonts.bodyEmphasis)
        }
    }

    private func togglePeriod(_ period: DayPeriod) {
        if schedule.periods.contains(period) {
            schedule.periods.remove(period)
        } else {
            schedule.periods.insert(period)
        }
    }

    private func toggleWeekday(_ day: Weekday) {
        if schedule.weekdays.contains(day) {
            schedule.weekdays.remove(day)
        } else {
            schedule.weekdays.insert(day)
        }
    }
}

private struct ScheduleChip: View {
    let title: String
    let isSelected: Bool
    let accent: AccentStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.secondary)
                .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        NeatControlFill(accent: accent, shape: Capsule(), speed: 0.85)
                    } else {
                        Capsule()
                            .fill(Theme.Colors.backgroundPrimary)
                    }
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : Theme.Colors.textSecondary.opacity(0.25),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

import SwiftUI

enum ArrivalPreference: String, CaseIterable, Identifiable {
    case onTime
    case early
    case fastest

    var id: String { rawValue }

    func label(for context: ArrivalPreferenceContext) -> String {
        switch self {
        case .onTime: "Right on time"
        case .early: "A few minutes early"
        case .fastest: "Whatever's fastest"
        }
    }
}

enum ArrivalPreferenceContext {
    case work
    case home
}

struct SerifExpandableTimePicker: View {
    let title: String
    let serifLabel: String
    @Binding var time: Date
    let accent: AccentStyle

    @State private var isExpanded = false

    private var formattedTime: String {
        time.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(spacing: 10) {
                    HStack {
                        Text(serifLabel)
                            .font(.playfairItalic(size: 24))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                        Text(formattedTime)
                            .font(.playfairItalic(size: 28))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .monospacedDigit()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    AccentGradientUnderline(
                        accent: accent,
                        height: 3,
                        isActive: true
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(serifLabel), arrive by \(formattedTime)")
            .accessibilityHint(isExpanded ? "Collapse time picker" : "Expand time picker")

            if isExpanded {
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                NeatControlFill(
                                    accent: accent,
                                    shape: RoundedRectangle(cornerRadius: 16, style: .continuous),
                                    presentation: .subtle
                                )
                            }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: isExpanded)
    }
}

struct ArrivalPreferencePicker: View {
    let label: String
    @Binding var preference: ArrivalPreference
    let accent: AccentStyle
    let context: ArrivalPreferenceContext

    private var options: [ArrivalPreference] {
        switch context {
        case .work: [.onTime, .early]
        case .home: [.onTime, .fastest]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: 10) {
                ForEach(options) { option in
                    preferenceChip(option)
                }
            }
        }
        .onAppear {
            if !options.contains(preference) {
                preference = .onTime
            }
        }
    }

    private func preferenceChip(_ option: ArrivalPreference) -> some View {
        let isSelected = preference == option
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                preference = option
            }
        } label: {
            Text(option.label(for: context))
                .font(.playfairItalic(size: 17))
                .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    if isSelected {
                        NeatControlFill(
                            accent: accent,
                            shape: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var time = Date()
        @State private var preference: ArrivalPreference = .onTime

        var body: some View {
            VStack(spacing: 32) {
                SerifExpandableTimePicker(
                    title: "Morning commute",
                    serifLabel: "At work by",
                    time: $time,
                    accent: .gradient(.neat)
                )
                ArrivalPreferencePicker(
                    label: "How do you like to arrive?",
                    preference: $preference,
                    accent: .gradient(.neat),
                    context: .work
                )
            }
            .padding()
        }
    }
    return PreviewWrapper()
}

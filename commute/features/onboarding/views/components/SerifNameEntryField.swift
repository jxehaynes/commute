import SwiftUI

struct SerifNameEntryField: View {
    @Binding var text: String
    let accent: AccentStyle
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                if text.isEmpty {
                    Text("Your name")
                        .font(.playfairItalic(size: OnboardingMetrics.nameEntrySize))
                        .foregroundStyle(Theme.Colors.textTertiary.opacity(0.7))
                }
                TextField("", text: $text)
                    .focused($isFocused)
                    .font(.playfairItalic(size: OnboardingMetrics.nameEntrySize))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .textContentType(.givenName)
                    .submitLabel(.continue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            AccentGradientUnderline(
                accent: accent,
                height: 3.5,
                isActive: isFocused || !text.isEmpty
            )
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel("First name")
        .onAppear { isFocused = true }
    }
}

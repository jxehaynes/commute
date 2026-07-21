import SwiftUI

struct CommutePrimaryButton: View {
    let label: String
    let accentStyle: AccentStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accentBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel(label)
        .accessibilityHint("Continues to the next step")
    }

    @ViewBuilder
    private var accentBackground: some View {
        NeatControlFill(accent: accentStyle, shape: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

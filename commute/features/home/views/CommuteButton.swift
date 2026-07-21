import SwiftUI

struct CommuteButton: View {
    let label: String
    let accentStyle: AccentStyle
    let action: () -> Void

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Layout {
        static let horizontalPadding: CGFloat = 24
        static let buttonHeight: CGFloat = 64
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Fonts.routeTime)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.buttonHeight)
                .background(buttonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .scaleEffect(reduceMotion ? 1 : (pulse ? 1.015 : 1))
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .accessibilityLabel(label)
        .accessibilityHint("Shows route options for today's journey")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    @ViewBuilder
    private var buttonBackground: some View {
        NeatControlFill(accent: accentStyle, shape: RoundedRectangle(cornerRadius: 16, style: .continuous), speed: 0.75)
    }
}

import SwiftUI

struct OnboardingAccentColourView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @EnvironmentObject private var appState: AppState

    var body: some View {
        OnboardingScreen(
            viewModel: viewModel,
            onContinue: { viewModel.advance(appState: appState) }
        ) {
            VStack(spacing: OnboardingMetrics.sectionSpacing) {
                OnboardingHeadline(parts: [.plain("Choose your "), .serif("accent")])
                OnboardingSubheadline(text: "Pick a palette - it'll follow you everywhere in the app.")

                AccentColorGridPicker(selection: accentSelection)

                accentPreview
            }
        }
    }

    private var accentSelection: Binding<AccentStyle> {
        Binding(
            get: { viewModel.accentStyle },
            set: { newStyle in
                viewModel.accentStyle = newStyle
                appState.setAccent(newStyle)
            }
        )
    }

    private var accentPreview: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text("This is what ")
                Text("accented text")
                    .font(.playfairItalic(size: 17))
                    .overlay(alignment: .bottom) {
                        AccentGradientUnderline(accent: viewModel.accentStyle, height: 3, speed: 0.9)
                            .offset(y: 4)
                    }
                Text(" looks like.")
                
            }
            .font(Theme.Fonts.routeSummary)
            .foregroundStyle(Theme.Colors.textPrimary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.25), value: viewModel.accentStyle)
    }
}

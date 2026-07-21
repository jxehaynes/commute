import SwiftUI

struct OnboardingScreen<Content: View>: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @EnvironmentObject private var appState: AppState

    let showsBack: Bool
    let showsContinue: Bool
    let continueLabel: String
    let continueEnabled: Bool
    let showsSkip: Bool
    let scrollable: Bool
    let onContinue: () -> Void
    let onSkip: (() -> Void)?
    @ViewBuilder let content: () -> Content

    init(
        viewModel: OnboardingFlowViewModel,
        showsBack: Bool = true,
        showsContinue: Bool = true,
        continueLabel: String = "Continue",
        continueEnabled: Bool = true,
        showsSkip: Bool = false,
        scrollable: Bool = false,
        onSkip: (() -> Void)? = nil,
        onContinue: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.viewModel = viewModel
        self.showsBack = showsBack
        self.showsContinue = showsContinue
        self.continueLabel = continueLabel
        self.continueEnabled = continueEnabled
        self.showsSkip = showsSkip
        self.scrollable = scrollable
        self.onSkip = onSkip
        self.onContinue = onContinue
        self.content = content
    }

    private var accent: AccentStyle {
        viewModel.resolvedAccent(appState: appState)
    }

    var body: some View {
        if scrollable {
            scrollableBody
        } else {
            standardBody
        }
    }

    private var standardBody: some View {
        VStack(spacing: 0) {
            Spacer(minLength: OnboardingMetrics.topContentInset)
            content()
                .frame(maxWidth: OnboardingMetrics.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, OnboardingMetrics.horizontalPadding)
            Spacer(minLength: 16)
            navigationBar
                .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                .padding(.bottom, 12)
        }
    }

    private var scrollableBody: some View {
        ScrollView {
            content()
                .frame(maxWidth: OnboardingMetrics.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                .padding(.top, OnboardingMetrics.topContentInset)
                .padding(.bottom, OnboardingMetrics.scrollBottomInset)
        }
        .scrollIndicators(.hidden)
        .mask { OnboardingScrollContentFade() }
        .overlay(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                OnboardingBottomAtmosphere()
                floatingNavigationBar
            }
        }
    }

    private var floatingNavigationBar: some View {
        navigationBar
            .padding(.horizontal, OnboardingMetrics.horizontalPadding)
            .padding(.vertical, 10)
            .padding(.bottom, 2)
    }

    private var navigationBar: some View {
        HStack {
            if showsBack, viewModel.currentStep != .welcome {
                LiquidGlassButton(
                    systemImage: "chevron.left",
                    label: "Back",
                    accentStyle: accent
                ) {
                    viewModel.back(appState: appState)
                }
            } else {
                Color.clear.frame(width: 88, height: 44)
            }

            Spacer()

            if showsSkip, let onSkip {
                Button("Skip") { onSkip() }
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.trailing, 8)
                    .accessibilityLabel("Skip this step")
            }

            if showsContinue {
                AccentGlassContinueButton(
                    label: continueLabel,
                    accentStyle: accent,
                    isEnabled: continueEnabled,
                    action: onContinue
                )
            }
        }
        .frame(minHeight: OnboardingMetrics.navBarHeight, alignment: .center)
    }
}

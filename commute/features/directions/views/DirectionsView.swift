import CommuteKit
import SwiftUI

struct DirectionsView: View {
    @ObservedObject var viewModel: DirectionsViewModel
    let profile: UserProfile
    let accent: AccentStyle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if viewModel.leg?.origin.naptanId != nil {
                    walkRow
                    arrivalsList
                }
                if !viewModel.remainingSteps.isEmpty {
                    remainingStepsRow
                }
            }
            .padding(Theme.Metrics.horizontalPadding)
        }
        .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Directions")
        .task { viewModel.start(profile: profile) }
        .onDisappear { viewModel.stop() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let leg = viewModel.leg {
                Text("\(leg.origin.displayName) → \(leg.destination.displayName)")
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            if let decision = viewModel.decision {
                decisionBanner(decision)
            } else if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    private func decisionBanner(_ decision: CommuteDecision.Result) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(decision.disruption.statusColor)
                .frame(width: 8, height: 8)
            Text(decision.disruptionMessage ?? (decision.waitMinutes <= 0 ? "Leave now" : "Leave in \(decision.waitMinutes) min"))
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    private var walkRow: some View {
        Label("Walk to stop · \(viewModel.walkMinutes) min", systemImage: LegKind.walk.systemImage)
            .font(Theme.Fonts.secondary)
            .foregroundStyle(Theme.Colors.textSecondary)
    }

    private var arrivalsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(viewModel.arrivals.prefix(4)) { arrival in
                HStack(spacing: 12) {
                    Image(systemName: arrival.mode.systemImage)
                        .foregroundStyle(accent.tintColor)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(arrival.lineName)
                            .font(Theme.Fonts.bodyEmphasis)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("to \(arrival.destinationName)")
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Spacer()

                    Text("\(Int(arrival.minutesAway().rounded())) min")
                        .font(Theme.Fonts.bodyEmphasis)
                        .foregroundStyle(arrival.id == viewModel.decision?.chosen?.id ? accent.tintColor : Theme.Colors.textPrimary)
                }
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: Theme.Metrics.cardCornerRadius, style: .continuous)
                        .fill(Theme.Colors.backgroundSurface)
                }
            }
        }
    }

    private var remainingStepsRow: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.remainingSteps) { step in
                Label(step.label, systemImage: step.icon)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DirectionsView(viewModel: DirectionsViewModel(), profile: UserProfile(), accent: .indigo)
    }
}

import CommuteKit
import SwiftUI
import WidgetKit

private let departureGrace: TimeInterval = 3 * 60

private func phase(now: Date, leaveBy: Date, arriveBy: Date) -> CommutePhase {
    if now >= arriveBy { return .arrived }
    if now >= leaveBy.addingTimeInterval(departureGrace) { return .enRoute }
    if now >= leaveBy { return .leaveNow }
    return .countdown
}

private extension CommuteWidgetSnapshot {
    /// Reuses the Live Activity's content-state-driven views by projecting
    /// the widget's lighter snapshot into the same shape, with no live
    /// disruption feed since the widget timeline never makes network calls.
    func contentState(now: Date) -> CommuteContentState {
        .init(
            leaveByDate: leaveByDate,
            arriveByDate: arriveByDate,
            etaMinutes: etaMinutes,
            routeSteps: routeSteps,
            disruption: .onTime,
            phase: phase(now: now, leaveBy: leaveByDate, arriveBy: arriveByDate)
        )
    }
}

struct NextCommuteEntry: TimelineEntry {
    var date: Date
    var snapshot: CommuteWidgetSnapshot?
}

struct NextCommuteProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextCommuteEntry {
        NextCommuteEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextCommuteEntry) -> Void) {
        let snapshot: CommuteWidgetSnapshot? = context.isPreview ? .preview : CommuteWidgetStore.load()
        completion(NextCommuteEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextCommuteEntry>) -> Void) {
        let now = Date.now

        guard let snapshot = CommuteWidgetStore.load(), snapshot.arriveByDate > now else {
            let entry = NextCommuteEntry(date: now, snapshot: nil)
            completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(30 * 60))))
            return
        }

        let transitionDates = [snapshot.leaveByDate, snapshot.leaveByDate.addingTimeInterval(departureGrace), snapshot.arriveByDate]
            .filter { $0 > now }
        let entries = ([now] + transitionDates).map { NextCommuteEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .after(snapshot.arriveByDate.addingTimeInterval(5 * 60))))
    }
}

struct CommuteNextCommuteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CommuteWidgetKind.nextCommute, provider: NextCommuteProvider()) { entry in
            NextCommuteWidgetView(entry: entry)
                .containerBackground(Theme.Colors.backgroundSurface, for: .widget)
                .widgetURL(URL(string: "commute://home"))
        }
        .configurationDisplayName("Next Commute")
        .description("Shows when to leave for your next scheduled commute.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct NextCommuteWidgetView: View {
    var entry: NextCommuteEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let snapshot = entry.snapshot {
            let state = snapshot.contentState(now: entry.date)
            switch family {
            case .systemMedium:
                MediumCommuteView(snapshot: snapshot, state: state)
            default:
                SmallCommuteView(snapshot: snapshot, state: state)
            }
        } else {
            EmptyCommuteView()
        }
    }
}

private struct SmallCommuteView: View {
    var snapshot: CommuteWidgetSnapshot
    var state: CommuteContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ModeGradientBadge(
                systemImage: snapshot.destinationIcon,
                gradient: snapshot.accent.gradient
            )

            Spacer(minLength: 0)

            DestinationHeadline(
                phase: state.phase,
                destinationLabel: snapshot.destinationLabel
            )
            .lineLimit(2)
            .minimumScaleFactor(0.8)

            CommuteCountdownText(
                state: state,
                accent: snapshot.accent,
                font: .system(size: 26, weight: .bold, design: .rounded)
            )

            Text(arrivalTimeText(snapshot.arriveByDate))
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

private struct MediumCommuteView: View {
    var snapshot: CommuteWidgetSnapshot
    var state: CommuteContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                ModeGradientBadge(
                    systemImage: snapshot.destinationIcon,
                    gradient: snapshot.accent.gradient
                )

                VStack(alignment: .leading, spacing: 2) {
                    DestinationHeadline(
                        phase: state.phase,
                        destinationLabel: snapshot.destinationLabel
                    )
                    Text(arrivalTimeText(snapshot.arriveByDate))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer(minLength: 8)

                CommuteCountdownText(state: state, accent: snapshot.accent)
            }

            if !state.routeSteps.isEmpty {
                RouteStepStrip(steps: state.routeSteps, accent: snapshot.accent)
            }

            LeaveProgressBar(state: state, accent: snapshot.accent)
        }
    }
}

private struct EmptyCommuteView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary)
            Text("No commute planned")
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("Add home and work in Commute to see your next leave time here.")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(3)
        }
    }
}

#Preview(as: .systemSmall) {
    CommuteNextCommuteWidget()
} timeline: {
    NextCommuteEntry(date: .now, snapshot: .preview)
    NextCommuteEntry(date: .now, snapshot: nil)
}

#Preview(as: .systemMedium) {
    CommuteNextCommuteWidget()
} timeline: {
    NextCommuteEntry(date: .now, snapshot: .preview)
}

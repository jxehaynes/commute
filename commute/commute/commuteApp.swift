//
//  commuteApp.swift
//  commute
//
//  Created by Joe Haynes on 25/05/2026.
//

import SwiftUI

@main
struct commuteApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await refreshLiveActivity() }
        }
    }

    /// Checks whether it's time to start the "time to leave" Live Activity,
    /// and advances the phase of one that's already running. Called whenever
    /// the app becomes active — there's no push-to-update server, so this is
    /// the primary refresh point; see `CommuteLiveActivityScheduler` for the
    /// background-refresh caveat.
    private func refreshLiveActivity() async {
        let etaProvider = StaticScheduleETAProvider(customRoute: appState.userProfile.customCommuteRoute)
        let scheduler = CommuteLiveActivityScheduler(etaProvider: etaProvider)
        await scheduler.checkAndStartIfNeeded(profile: appState.userProfile)
        await scheduler.refresh(profile: appState.userProfile)
    }
}

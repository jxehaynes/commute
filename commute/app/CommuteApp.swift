import SwiftUI

@main
struct CommuteApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    @State private var backgroundRefreshManager = CommuteBackgroundRefreshManager()
    @State private var didRegisterBackgroundTasks = false

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(appState)
                .onAppear {
                    backgroundRefreshManager.configure { appState.userProfile }
                    if !didRegisterBackgroundTasks {
                        backgroundRefreshManager.register()
                        didRegisterBackgroundTasks = true
                    }
                    Task { await backgroundRefreshManager.runForegroundCheck() }
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task { await backgroundRefreshManager.runForegroundCheck() }
                backgroundRefreshManager.startForegroundPollingIfNeeded()
            case .background, .inactive:
                backgroundRefreshManager.stopForegroundPolling()
            @unknown default:
                break
            }
        }
    }
}

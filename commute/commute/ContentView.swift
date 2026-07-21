//
//  ContentView.swift
//  commute
//
//  Created by Joe Haynes on 25/05/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.arrivalsRepository) private var arrivalsRepository
    @State private var directionsViewModel: DirectionsViewModel?
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if let directionsViewModel {
                    DirectionsView(
                        viewModel: directionsViewModel,
                        profile: appState.userProfile,
                        accent: appState.accentStyle
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onAppear {
            if directionsViewModel == nil {
                directionsViewModel = DirectionsViewModel(repository: arrivalsRepository)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

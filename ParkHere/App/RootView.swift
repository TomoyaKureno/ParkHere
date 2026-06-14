//
//  RootView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 06/06/26.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var waypointStore = WaypointStore() // nb: environment object is used when a view needs access to an object created somewhere above it
    @StateObject private var locationManager = UserLocationManager()
    @StateObject private var altimeterManager = AltimeterManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView {
                hasSeenOnboarding = true
            }
        } else {
            NavigationStack(path: $appCoordinator.path) {
                HomeView(
                    store: waypointStore,
                    locationManager: locationManager,
                    onSaveParkingSpot: {
                        appCoordinator.push(.camera)
                    },
                    onFindParkingSpot: {
                        waypointStore.prepareTracking()
                        appCoordinator.push(.tracker)
                    }
                )
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .camera:
                        CameraView(store: waypointStore, locationManager: locationManager, altimeterManager: altimeterManager) {
                            appCoordinator.pop()
                        } onPop: {
                            appCoordinator.pop()
                        }
                    case .tracker:
                        TrackerView(store: waypointStore, locationManager: locationManager, altimeterManager: altimeterManager) {
                            appCoordinator.popToRoot()
                        }
                    }
                }
            }
            .environmentObject(appCoordinator) // Share navigation
            .task {
                let repository = ParkingRepository(modelContext: modelContext)
                waypointStore.attach(repository: repository)
                waypointStore.restoreFromPresistence()
            }
        }
    }
}

#Preview {
    RootView()
}

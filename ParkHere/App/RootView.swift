//
//  RootView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 06/06/26.
//

import SwiftData
import SwiftUI

struct RootView: View {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var waypointStore = WaypointStore()
    @StateObject private var locationManager = UserLocationManager()
    @StateObject private var altimeterManager = AltimeterManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("hasSeenLocationOnboarding") private var hasSeenLocationOnboarding: Bool = false
    @State private var showLocationOnboarding = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView {
                hasSeenOnboarding = true
                if !hasSeenLocationOnboarding {
                    showLocationOnboarding = true
                }
            }
        } else if !hasSeenLocationOnboarding || showLocationOnboarding {
            LocationOnboardingView(isPresented: Binding(
                get: { !hasSeenLocationOnboarding },
                set: { hasSeenLocationOnboarding = !$0; showLocationOnboarding = $0 }
            )) {
                hasSeenLocationOnboarding = true
                locationManager.requestAccessAndStartUpdating()
            }
        } else {
            NavigationStack(path: $appCoordinator.path) {
                HomeView(
                    store: waypointStore,
                    locationManager: locationManager,
                    onSaveParkingSpot: {
                        appCoordinator.push(.camera(retakeIndex: nil))
                    },
                    onFindParkingSpot: {
                        waypointStore.prepareTracking()
                        appCoordinator.push(.tracker)
                    }
                )
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .camera(let retakeIndex):
                        CameraView(
                            store: waypointStore,
                            locationManager: locationManager,
                            altimeterManager: altimeterManager,
                            retakeIndex: retakeIndex
                        ) {
                            appCoordinator.pop()
                        } onPop: {
                            appCoordinator.pop()
                        } onTapLandmarks: {
                            appCoordinator.push(
                                .landmark(isGallery: true)
                            )
                        }
                    case .tracker:
                        TrackerView(store: waypointStore, locationManager: locationManager, altimeterManager: altimeterManager) {
                            appCoordinator.popToRoot()
                        } onTapBack: {
                            appCoordinator.pop()
                        } onTapLandmarks: { isGallery in
                            appCoordinator.push(
                                .landmark(isGallery: isGallery)
                            )
                        }
                    case .landmark(let isGallery):
                        LandmarksView(
                            store: waypointStore,
                            isGallery: isGallery,
                            currentLandmarkIndex: currentLandmarkIndex()
                        ) {
                            appCoordinator.pop()
                        } onUseLandmark: { index in
                            waypointStore.useLandmarkInstead(at: index)
                            appCoordinator.pop()
                        } onRetakeLandmark: { index in
                            appCoordinator.push(.camera(retakeIndex: index))
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

    private func currentLandmarkIndex() -> Int {
        guard let currentIndex = waypointStore.currentTrackingPhotoIndex else { return 0 }

        return max(0, waypointStore.capturedImages.count - 1 - currentIndex)
    }
}

#Preview {
    RootView()
}

//
//  HomeView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 04/06/26.
//

import CoreLocation
import SwiftUI

struct HomeView: View {
    @ObservedObject var store: WaypointStore
    @ObservedObject var locationManager: UserLocationManager

    let onSaveParkingSpot: () -> Void
    let onFindParkingSpot: () -> Void

    @State private var isSavingParkingSpot = false
    @State private var showClearParkingSpotAlert = false

    var body: some View {
        ZStack {
            Color.surfacePrimaryBlack
                .ignoresSafeArea()

            VStack {
                if locationManager.authorizationStatus == .denied {
                    UnavailableView(
                        systemImage: "location.slash.fill",
                        title: "Location Access is Off",
                        subtitle: "Turn on your location services to save your parking spot and capture waypoints",
                        buttonTitle: "Open Settings"
                    ) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                } else {
                    if store.hasCompletedParkingCapture, let parkingSpot = store.capturedWaypoints.first {
                        VStack {
                            HomeHasParkingSpotView(parkingSpotData: parkingSpot)
                        }

                        Spacer()

                        VStack(spacing: 12) {
                            Button {
                                store.prepareTracking()
                                onFindParkingSpot()
                            } label: {
                                Text("Navigate to Car")
                            }
                            .buttonStyle(.primaryStyle)

                            Button {
                                showClearParkingSpotAlert = true
                            } label: {
                                Text("Capture Parking Spot")
                            }
                            .buttonStyle(.secondaryStyle)
                        }

                    } else {
                        HStack {
                            HomeCurrentLocationView(landmark: locationManager.currentLandmark)
                            Spacer()
                        }

                        Spacer()

                        HomeEmptyStateView()

                        Spacer()

                        VStack(spacing: 12) {
                            Button {
                                saveParkingSpot()
                            } label: {
                                if isSavingParkingSpot || locationManager.isRequestingLocation {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Capture Parking Spot")
                                }
                            }
                            .buttonStyle(.primaryStyle)
                            .disabled(isSavingParkingSpot || locationManager.isRequestingLocation)
                        }
                    }
                }
            }
            .safeAreaPadding()
        }
        .onAppear {
            locationManager.requestAccessAndStartUpdating()
        }
        .alert("Replace Saved Parking Spot?", isPresented: $showClearParkingSpotAlert) {
            Button("Replace", role: .confirm) {
                store.clearParkingSpot()
                showClearParkingSpotAlert = false
            }
            .tint(Color.brandPrimaryBlue)
            .keyboardShortcut(.defaultAction)

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete your current parking spot and all associated waypoint photos.")
        }
    }

    // MARK: - Private Function

    private func saveParkingSpot() {
        isSavingParkingSpot = true
        locationManager.requestCurrentLocation { location in
            guard let location else {
                isSavingParkingSpot = false

                return
            }

            store.saveParkingLocation(location)
            store.clearWaypoints()
            isSavingParkingSpot = false
            onSaveParkingSpot()
        }
    }
}

#Preview("Preview Dark Mode") {
    @Previewable @StateObject var store = WaypointStore()
    @Previewable @StateObject var locationManager = UserLocationManager()

    HomeView(
        store: store,
        locationManager: locationManager,
        onSaveParkingSpot: {},
        onFindParkingSpot: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Preview Light Mode") {
    @Previewable @StateObject var store = WaypointStore()
    @Previewable @StateObject var locationManager = UserLocationManager()

    HomeView(
        store: store,
        locationManager: locationManager,
        onSaveParkingSpot: {},
        onFindParkingSpot: {}
    )
}

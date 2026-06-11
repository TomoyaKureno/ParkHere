//
//  HomeView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 04/06/26.
//

import SwiftUI
import CoreLocation

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
                if (locationManager.authorizationStatus == .denied) {
                    Spacer ()
                    
                    LocationDeniedView()
                } else {
                    if (store.hasSavedParkingSpot) {
                        VStack {
                            HomeHasParkingSpotView()
                        }
                        
                    } else {
                        HStack {
                            HomeCurrentLocationView()
                            Spacer()
                        }
                        
                        Spacer()
                        
                        HomeEmptyStateView()
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    if (locationManager.authorizationStatus == .denied) {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Open Settings")
                                .foregroundStyle(Color.surfaceSecondaryWhite)
                        }
                        .buttonStyle(.primaryStyle)

                    } else {
                        if (store.hasSavedParkingSpot) {
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
                            
                        } else {
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
                            .disabled(store.hasSavedParkingSpot || isSavingParkingSpot)
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
            
            Button("Cancel", role: .cancel) {
            }
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

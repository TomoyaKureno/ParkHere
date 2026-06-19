//
//  HomeView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 04/06/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var store: LandmarkStore
    @ObservedObject var locationManager: UserLocationManager
    @StateObject private var viewModel: HomeViewModel

    let onSaveParkingSpot: () -> Void
    let onFindParkingSpot: () -> Void

    init(
        store: LandmarkStore,
        locationManager: UserLocationManager,
        onSaveParkingSpot: @escaping () -> Void,
        onFindParkingSpot: @escaping () -> Void
    ) {
        self.store = store
        self.locationManager = locationManager
        self.onSaveParkingSpot = onSaveParkingSpot
        self.onFindParkingSpot = onFindParkingSpot
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                store: store,
                locationManager: locationManager
            )
        )
    }

    var body: some View {
        ZStack {
            Color.surfacePrimaryBlack
                .ignoresSafeArea()

            VStack {
                if viewModel.isLocationUnavailable {
                    UnavailableView(
                        systemImage: "location.slash.fill",
                        title: "Location Access is Off",
                        subtitle: "Turn on your location services to save your parking spot and capture landmarks",
                        buttonTitle: "Open Settings"
                    ) {
                        viewModel.openSettings()
                    }
                } else {
                    if let parkingSpot = viewModel.parkingSpot {
                        VStack {
                            HomeHasParkingSpotView(parkingSpotData: parkingSpot)
                        }

                        Spacer()

                        VStack(spacing: 12) {
                            Button {
                                onFindParkingSpot()
                            } label: {
                                Text("Navigate to Car")
                            }
                            .buttonStyle(.primaryStyle)

                            Button {
                                viewModel.requestReplaceParkingSpot()
                            } label: {
                                Text("Capture Parking Spot")
                            }
                            .buttonStyle(.secondaryStyle)
                        }

                    } else {
                        HStack {
                            HomeCurrentLocationView(landmark: viewModel.currentLandmark)
                            Spacer()
                        }

                        Spacer()

                        HomeEmptyStateView()

                        Spacer()

                        VStack(spacing: 12) {
                            Button {
                                viewModel.saveParkingSpot(onSaveParkingSpot: onSaveParkingSpot)
                            } label: {
                                Text("Capture Parking Spot")
                            }
                            .buttonStyle(.primaryStyle)
                        }
                    }
                }
            }
            .safeAreaPadding()
        }
        .onAppear {
            viewModel.onAppear()
        }
        .alert("Replace Saved Parking Spot?", isPresented: $viewModel.showClearParkingSpotAlert) {
            Button("Replace", role: .confirm) {
                viewModel.confirmReplaceParkingSpot(onSaveParkingSpot: onSaveParkingSpot)
            }
            .tint(Color.brandPrimaryBlue)
            .keyboardShortcut(.defaultAction)

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete your current parking spot and all associated landmark photos.")
        }
    }
}

#Preview("Preview Dark Mode") {
    @Previewable @StateObject var store = LandmarkStore()
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
    @Previewable @StateObject var store = LandmarkStore()
    @Previewable @StateObject var locationManager = UserLocationManager()

    HomeView(
        store: store,
        locationManager: locationManager,
        onSaveParkingSpot: {},
        onFindParkingSpot: {}
    )
}

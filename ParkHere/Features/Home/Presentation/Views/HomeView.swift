//
//  HomeView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 04/06/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var store: WaypointStore
    @ObservedObject var locationManager: UserLocationManager

    let onSaveParkingSpot: () -> Void
    let onFindParkingSpot: () -> Void

    @State private var isSavingParkingSpot = false

    var body: some View {
        ZStack {
            Color.surfacePrimaryBlack
                .ignoresSafeArea()

            VStack(spacing: 38) {
                Spacer()

                VStack(spacing: 28) {
                    HomeIconView()

                    HomeTItleView(
                        title: "Save Your Parking Spot",
                        description: locationManager.statusText
                    )

                    HomeCardView(hasSavedLocation: .constant(store.hasSavedParkingSpot))
                }

                VStack(spacing: 8) {
                    Button {
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
                    } label: {
                        if isSavingParkingSpot || locationManager.isRequestingLocation {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Parking Spot")
                        }
                    }
                    .buttonStyle(.primaryStyle)
                    .disabled(store.hasSavedParkingSpot || isSavingParkingSpot)

                    Button {
                        store.prepareTracking()
                        onFindParkingSpot()
                    } label: {
                        Text("Find Parking Spot")
                    }
                    .buttonStyle(.primaryStyle)
                    .disabled(!store.hasSavedParkingSpot)
                }

                Spacer()
            }
        }
        .onAppear {
            locationManager.requestAccessAndStartUpdating()
        }
    }
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

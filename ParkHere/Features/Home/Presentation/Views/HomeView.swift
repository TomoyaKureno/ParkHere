//
//  HomeView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 04/06/26.
//

import SwiftUI

struct HomeView: View {
    let onSaveParkingSpot: () -> Void
    let onFindParkingSpot: () -> Void

    @State private var hasSavedLocation: Bool = false

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
                        description: "We'll capture your current location so you can easily navigate back to your parking."
                    )

                    HomeCardView(hasSavedLocation: $hasSavedLocation)
                }

                VStack(spacing: 8) {
                    Button {
                        hasSavedLocation = true
                        onSaveParkingSpot()
                    } label: {
                        Text("Save Parking Spot")
                    }
                    .buttonStyle(.primaryStyle)
                    .disabled(hasSavedLocation)

                    Button {
                        onFindParkingSpot()
                    } label: {
                        Text("Find Parking Spot")
                    }
                    .buttonStyle(.primaryStyle)
                    .disabled(!hasSavedLocation)
                }

                Spacer()
            }
        }
    }
}

#Preview("Preview Light Mode") {
    HomeView(
        onSaveParkingSpot: {},
        onFindParkingSpot: {}
    )
}

#Preview("Preview Dark Mode") {
    HomeView(
        onSaveParkingSpot: {},
        onFindParkingSpot: {}
    )
    .preferredColorScheme(.dark)
}

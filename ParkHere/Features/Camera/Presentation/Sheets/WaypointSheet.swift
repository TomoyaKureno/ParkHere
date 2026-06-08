//
//  WaypointSheet.swift
//  ParkHere
//
//  Created by Kelly Angeline on 04/06/26.
//

import SwiftUI

struct WaypointSheet: View {
    @EnvironmentObject private var waypointStore: WaypointStore
    
    let onSaveParkingSpot: () -> Void
    
    var body: some View {
        VStack {
            Text("Your Waypoint Photos")
                .font(.title3Bold)
                .padding(7)
            Text(
                "The route that  will help guide you back to your car."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.bottom, 30)
            HStack {
                Text("Your Waypoints")
                    .font(.callout)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(waypointStore.capturedImages.count) Photos")
                    .font(.subheadlineReg)
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal)
            ScrollView {
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ],
                    alignment: .leading,
                    spacing: 10
                ) {
                    ForEach(Array(waypointStore.capturedImages.enumerated()), id:\.offset) {
                        index, image in
                            let isFirst = index == 0
                            let isLast = index == waypointStore.capturedImages.count - 1
                            
                        ZStack(alignment:.topLeading) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height:120)
                                .clipped()
                                .clipShape(
                                    RoundedRectangle(cornerRadius:12)
                                )
                            
                            if isFirst {
                                WaypointLabel(
                                    text: "Parking Spot",
                                    color: .blue
                                )
                            } else if isLast {
                                WaypointLabel(
                                    text: "Final Spot",
                                    color: .green)
                            } else {
                                WaypointLabel(
                                    text: "Waypoint \(index)",
                                    color: .gray)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)

        }
        .padding(.top, 30)
    }
}

#Preview {
    WaypointSheet(
        onSaveParkingSpot: {}
    )
    .environmentObject(WaypointStore())
}

//
//  WaypointView.swift
//  ParkHere
//
//  Created by Kelly Angeline on 04/06/26.
//

import SwiftUI

struct WaypointView: View {
    var body: some View {
        VStack {
            Text("Your Waypoint Photos")
                .font(.title2)
                .bold()
                .padding(5)
            Text(
                "These photos will help guide you back to your car."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, 15)
            HStack {
                Text("Your Waypoints")
                    .font(.headline)
                Spacer()
                Text("4 Photos")
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
                    ForEach(0..<4, id: \.self) { column in

                        if column == 0 {
                            ZStack(alignment: .topLeading) {
                                Image("valak")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 120)
                                    .clipped()
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 12)
                                    )
                                WaypointLabel(
                                    text: "Parking Spot",
                                    color: .blue
                                )
                                .padding(8)
                            }
                        } else if column == 3 {
                            ZStack(alignment: .topLeading) {
                                Image("valak")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 120)
                                    .clipped()
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 12)
                                    )
                                WaypointLabel(
                                    text: "Final Spot",
                                    color: .green
                                )
                                .padding(8)
                            }
                        } else {
                            Image("valak")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }.padding()
            }
            Spacer()
            Button(action: {
                print("Button Clicked")
            }) {
                Text("Add Another Waypoint")
                    .frame(maxWidth: 250)
                    .font(.body)
                    .bold()
            }
            .buttonStyle(BorderedButtonStyle())
            .controlSize(.large)
            Button(action: {
                print("Button Clicked")
            }) {
                Text("Save Parking Spot")
                    .frame(maxWidth: 250)
                    .font(.body)
                    .bold()
            }
            .controlSize(.large)
            .buttonStyle(BorderedProminentButtonStyle())

        }
    }
}

#Preview {
    WaypointView()
}

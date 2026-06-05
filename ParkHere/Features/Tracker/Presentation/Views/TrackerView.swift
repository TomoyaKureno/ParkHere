//
//  TrackerView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 05/06/26.
//

import SwiftUI

struct TrackerView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            GeometryReader { proxy in
                let diameter = proxy.size.width * 3

                VStack {
                    Spacer()

                    VStack {
                        Button {
                            
                        } label: {
                            Text("Found it!")
                                .foregroundStyle(.white)
                                .font(.headline)
                                .padding()
                                .frame(width: 272)
                            
                        }
                        .background(.blue)
                        .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)
                .background {
                    Circle()
                        .fill(Color(red: 190/255, green: 190/255, blue: 190/255))
                        .frame(width: diameter, height: diameter)
                        .position(
                            x: proxy.size.width/2,
                            y: proxy.size.height + diameter * 0.225
                        )
                }
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 16) {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Find Your Car")
                            .foregroundStyle(.white)
                            .font(.title.bold())

                        Text("Follow your saved waypoint to get back to your parking spot")
                            .foregroundStyle(Color(red: 235/255, green: 235/255, blue: 245/255))
                    }
                    .multilineTextAlignment(.center)

                    Image("imgWaypoint")
                        .resizable()
                        .scaledToFill()
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay(alignment: .topLeading) {
                            Text("3 Waypoints to go")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.green)
                                .clipShape(Capsule())
                                .offset(x: 16, y: 13)
                        }

                    VStack(spacing: 8) {
                        Text("Can't find this waypoint?")
                            .foregroundStyle(Color(red: 235/255, green: 235/255, blue: 245/255))

                        Button {} label: {
                            HStack(spacing: 8) {
                                Image(systemName: "car.fill")
                                Text("Show Parking Spot")
                            }
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.gray)
                        }
                        .clipShape(Capsule())
                        .glassEffect(.regular)
                    }
                }
                .padding(.horizontal, 32)

                VStack {
                    ZStack {
//                        Circle()
//                            .frame(width: 1000, height: 1000)
                    }
                }.frame(maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    TrackerView()
}

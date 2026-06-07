//
//  TrackerView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 05/06/26.
//

import SwiftUI

struct TrackerView: View {
    let onFoundIt: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            GeometryReader { proxy in
                let diameter = proxy.size.width * 3

                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 16) {
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 160).bold())
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 16) {
                        HStack {
                            Spacer()

                            VStack {
                                Text("est.")
                                HStack(spacing: 8) {
                                    Image(systemName: "figure.walk")
                                    Text("65m")
                                }
                                .font(.largeTitle.bold())
                            }.foregroundStyle(.white)

                            Spacer()

                            VStack {}
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                                .background(.gray)
                                .clipShape(Capsule())

                            Spacer()

                            VStack {
                                Text("est.")

                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up")
                                    Text("2 Floor")
                                }
                                .font(.largeTitle.bold())
                            }.foregroundStyle(.white)
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .frame(height: 95)
                        .background(.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 50))

                        Button {} label: {
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
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)
                .background {
                    Circle()
                        .fill(.green)
//                        .fill(Color(red: 190/255, green: 190/255, blue: 190/255))
                        .frame(width: diameter, height: diameter)
                        .position(
                            x: proxy.size.width/2,
                            y: proxy.size.height + diameter * 0.15
                        )
                }
            }
            .ignoresSafeArea(edges: .bottom)

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
                    .scaledToFit()
                    .clipped()
                    .frame(maxWidth: .infinity)
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
                    .overlay(alignment: .topLeading) {
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.8), location: 0.0),
                                .init(color: .black.opacity(0.4), location: 0.3),
                                .init(color: .clear, location: 0.4)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .clipShape(
                            UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 14, bottomTrailing: 14))
                        )
                        .padding(.horizontal, 9)
                        .padding(.bottom, 13)
                    }
                    .overlay(alignment: .bottom) {
                        VStack(spacing: 8) {
                            Text("Can't find this waypoint?")
                                .font(.footnote)
                                .foregroundStyle(.white)

                            Button {} label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "car.fill")
                                    Text("Show Parking Spot")
                                }
                                .font(.footnote)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.gray)
                            }
                            .clipShape(Capsule())
                            .glassEffect(.regular)
                        }
                        .frame(maxWidth: .infinity)
                        .offset(y: -24)
                    }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    TrackerView(onFoundIt: {})
}

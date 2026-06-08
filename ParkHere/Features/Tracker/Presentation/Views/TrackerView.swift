//
//  TrackerView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 05/06/26.
//

import SwiftUI

struct TrackerView: View {
    @ObservedObject var viewModel: CameraViewModel
    let onFoundIt: () -> Void
    @State var toDegree: CGFloat = 180.0
    @State private var showAlert = false

    var body: some View {
        ZStack {
            Color.surfacePrimaryBlack
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Find Your Car")
                        .foregroundStyle(Color.surfaceSecondaryWhite)
                        .font(.title.bold())

                    Text("Follow your saved waypoint to get back to your parking spot")
                        .foregroundStyle(Color.surfaceSecondaryWhite)
                        .font(.subheadline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

                Image("imgWaypoint")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 264)
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
                            .background(Color.brandAccentGreen)
                            .clipShape(Capsule())
                            .offset(x: 12, y: 12)
                    }

                if !viewModel.capturedWaypoints.isEmpty {
                    VStack(spacing: 8) {
                        Text("Can't find this waypoint?")
                            .font(.footnote)
                            .foregroundStyle(.white)

                        Button {} label: {
                            HStack(spacing: 8) {
                                Image(systemName: AppIcon.carFill)
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
                }

                VStack(spacing: 16) {
                    Spacer(minLength: 0)

                    ZStack(alignment: .top) {
                        let arcInset: CGFloat = 16
                        let isArcFlipped = toDegree > 180
                        let arcDegree = isArcFlipped ? 360 - toDegree : toDegree
                        let arcVisibleDegree = max(0, arcDegree - arcInset * 2)
                        let arcStart = arcInset / 360
                        let arcEnd = (arcInset + arcVisibleDegree) / 360
                        let shouldHideArc = arcVisibleDegree <= 0
                        let shouldHideRotatingDot = toDegree <= 0 || toDegree >= 360

                        Circle()
                            .fill(.white)
                            .frame(width: 16, height: 16)

                        Circle()
                            .trim(from: arcStart, to: arcEnd)
                            .stroke(
                                .white.opacity(0.8),
                                style: StrokeStyle(
                                    lineWidth: 16,
                                    lineCap: .round
                                )
                            )
                            .rotationEffect(.degrees(-90))
                            .scaleEffect(x: isArcFlipped ? -1 : 1)
                            .opacity(shouldHideArc ? 0 : 1)
                            .padding(10)
                            .overlay {
                                Image(systemName: AppIcon.arrowUp)
                                    .font(.system(size: 116).bold())
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .overlay(alignment: .top) {
                                        Circle()
                                            .fill(.gray)
                                            .frame(width: 16, height: 16)
                                            .opacity(shouldHideRotatingDot ? 0 : 1)
                                    }
                                    .rotationEffect(.degrees(toDegree))
                            }
                    }
                    .frame(width: 200, height: 200)
                    .animation(
                        .interpolatingSpring(
                            stiffness: 120,
                            damping: 12
                        ),
                        value: toDegree
                    )

                    Spacer(minLength: 0)

                    HStack {
                        Spacer()

                        VStack {
                            Text("est.")
                            HStack(spacing: 8) {
                                Image(systemName: AppIcon.figureWalk)
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
                    .clipShape(RoundedRectangle(cornerRadius: 30))

                    if viewModel.capturedWaypoints.isEmpty {
                        Button("Found it!") {}
                            .buttonStyle(.primaryStyle)
                    }
                }
                .frame(maxWidth: .infinity)
                .background {
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        let diameter = width * 3

                        Circle()
                            .fill(toDegree == 344 || toDegree == 16 ? Color.brandAccentGreen : Color.surfaceGray)
                            .frame(width: diameter, height: diameter)
                            .position(
                                x: width / 2,
                                y: diameter / 2
                            )
                    }
                    .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden()
        .alert("Found your car ?", isPresented: $showAlert) {
            Button("Not Yet", role: .cancel) {}

            Button("Done") {
                onFoundIt()
            }
        } message: {
            Text("This will clear your saved parking spot and waypoint photos")
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = CameraViewModel()

    TrackerView(viewModel: viewModel) {}
        .preferredColorScheme(.dark)
}

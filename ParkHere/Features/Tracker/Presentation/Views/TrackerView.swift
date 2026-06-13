//
//  TrackerView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 05/06/26.
//

import SwiftUI

struct TrackerView: View {
    @ObservedObject var store: WaypointStore
    @ObservedObject var locationManager: UserLocationManager

    let onFoundIt: () -> Void

    @State private var showAlert = false
    @State private var showSkipToParkingSpotAlert = false
    @State private var displayedArrowDegree: CGFloat = 0
    @State private var isForwardLocked = false
    @State private var isArrivalConfirmed = false

    private let forwardEnterInset: CGFloat = 20
    private let forwardExitInset: CGFloat = 30

    var body: some View {
        let directionDegree = locationManager.relativeBearing(to: store.currentTrackingCoordinate) ?? 0
        let isInsideForwardEnterInset = isInsideForwardRange(directionDegree, inset: forwardEnterInset)
        let isInsideForwardExitInset = isInsideForwardRange(directionDegree, inset: forwardExitInset)
        let shouldLockForward = isForwardLocked ? isInsideForwardExitInset : isInsideForwardEnterInset
        let normalizedArrowDegree = normalizedDegree(displayedArrowDegree)
        let distanceText = locationManager.distanceText(to: store.currentTrackingCoordinate)
        let isInsideArrivalRadius = locationManager.isInsideArrivalRadius(
            targetCoordinate: store.currentTrackingCoordinate,
            targetAccuracy: store.currentTrackingHorizontalAccuracy
        )
        let isOutsideArrivalExitRadius = locationManager.isOutsideArrivalExitRadius(
            targetCoordinate: store.currentTrackingCoordinate
        )
        let isTrackingParkingSpot = store.isTrackingParkingSpot
        let directionInstruction = locationManager.directionInstruction(
            for: shouldLockForward ? 0 : normalizedArrowDegree,
            isFound: isArrivalConfirmed,
            isTrackingParkingSpot: isTrackingParkingSpot
        )
        let distanceUpdateKey = locationManager.distance(to: store.currentTrackingCoordinate) ?? .greatestFiniteMagnitude

        ZStack {
            Color.surfacePrimaryBlack
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Find Your Car")
                        .font(.titleBold)

                    Text("Follow your saved waypoint to get back to your parking spot")
                        .font(.subheadlineReg)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                        .opacity(0.5)
                }
                .foregroundStyle(Color.surfaceSecondaryWhite)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

                waypointImage
                    .resizable()
                    .scaledToFill()
                    .frame(height: 264)
                    .frame(maxWidth: .infinity)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(alignment: .topLeading) {
                        if isTrackingParkingSpot {
                            WaypointLabel(text: "Parking Spot", color: .brandPrimaryBlue)
                        } else {
                            WaypointLabel(text: "\(store.remainingWaypointCount) waypoints to go", color: .brandAccentGreen)
                        }
                    }

                if !isTrackingParkingSpot {
                    VStack(spacing: 8) {
                        Text("Can't find this waypoint?")
                            .opacity(0.5)

                        Button {
                            showSkipToParkingSpotAlert = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: AppIcon.carFill)
                                Text("Show Parking Spot")
                            }
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.gray)
                        }
                        .clipShape(Capsule())
                        .glassEffect(.regular)
                    }
                    .font(.footnoteReg)
                    .foregroundStyle(Color.surfaceSecondaryWhite)
                    .frame(maxWidth: .infinity)
                }

                VStack(spacing: 16) {
                    Spacer(minLength: 0)

                    ZStack(alignment: .top) {
                        let arcInset = forwardEnterInset
                        let isArcFlipped = normalizedArrowDegree > 180
                        let arcDegree = isArcFlipped ? 360 - normalizedArrowDegree : normalizedArrowDegree
                        let arcVisibleDegree = max(0, arcDegree - arcInset * 2)
                        let arcStart = arcInset / 360
                        let arcEnd = (arcInset + arcVisibleDegree) / 360
                        let shouldHideArc = arcVisibleDegree <= 0

                        if isArrivalConfirmed {
                            Image(systemName: AppIcon.checkmark)
                                .font(.system(size: 116).bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Circle()
                                .fill(.white)
                                .frame(width: 16, height: 16)
                                .opacity(shouldLockForward ? 0 : 1)

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
                                                .fill(shouldLockForward ? .white : .gray)
                                                .frame(width: 16, height: 16)
                                        }
                                        .rotationEffect(.degrees(displayedArrowDegree))
                                }
                        }
                    }
                    .frame(width: 200, height: 200)
                    .animation(
                        .interpolatingSpring(
                            stiffness: 120,
                            damping: 12
                        ),
                        value: isArrivalConfirmed
                    )

                    Text(directionInstruction)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Spacer(minLength: 0)

                    HStack {
                        Spacer()

                        VStack {
                            Text("est.")
                            HStack(spacing: 8) {
                                Image(systemName: AppIcon.figureWalk)
                                Text(distanceText)
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

                    if isTrackingParkingSpot, store.currentTrackingCoordinate != nil {
                        Button("Found it!") {
                            guard isArrivalConfirmed else { return }

                            showAlert = true
                        }
                        .buttonStyle(.primaryStyle)
                        .disabled(!isArrivalConfirmed)
                    }
                }
                .frame(maxWidth: .infinity)
                .background {
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        let diameter = width * 3

                        Circle()
                            .fill(isArrivalConfirmed || isInsideArrivalRadius || shouldLockForward ? Color.brandAccentGreen : Color.surfaceGray)
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
        .onAppear {
            locationManager.requestAccessAndStartUpdating()
            updateForwardLockAndArrow(for: directionDegree, animated: false)
            updateArrivalState(
                isInsideArrivalRadius: isInsideArrivalRadius,
                isOutsideArrivalExitRadius: isOutsideArrivalExitRadius
            )
        }
        .onChange(of: distanceUpdateKey) { _, _ in
            updateArrivalState(
                isInsideArrivalRadius: isInsideArrivalRadius,
                isOutsideArrivalExitRadius: isOutsideArrivalExitRadius
            )

            if !isArrivalConfirmed {
                updateForwardLockAndArrow(for: directionDegree)
            }
        }
        .onChange(of: isArrivalConfirmed) { _, newValue in
            advanceWaypointIfNeeded(isArrivalConfirmed: newValue)
        }
        .onChange(of: directionDegree) { _, _ in
            guard !isInsideArrivalRadius else { return }

            updateForwardLockAndArrow(for: directionDegree)
        }
        .navigationBarBackButtonHidden()
        .alert("Found your car ?", isPresented: $showAlert) {
            Button("Not Yet", role: .cancel) {}

            Button("Done") {
                store.clearParkingSpot()
                resetArrivalState()
                onFoundIt()
            }
        } message: {
            Text("This will clear your saved parking spot and waypoint photos")
        }
        .alert("Skip to parking spot?", isPresented: $showSkipToParkingSpotAlert) {
            Button("Cancel", role: .cancel) {}

            Button("Show Parking Spot") {
                skipToParkingSpot()
            }
        } message: {
            Text("This will skip the remaining waypoints and guide you directly to your saved parking spot.")
        }
    }

    private var waypointImage: Image {
        if let currentTrackingImage = store.currentTrackingImage {
            return Image(uiImage: currentTrackingImage)
        }

        return Image("imgWaypoint")
    }

    private func isInsideForwardRange(_ degree: CGFloat, inset: CGFloat) -> Bool {
        degree <= inset || degree >= 360 - inset
    }

    private func updateForwardLockAndArrow(for degree: CGFloat, animated: Bool = true) {
        let nextIsForwardLocked = isForwardLocked
            ? isInsideForwardRange(degree, inset: forwardExitInset)
            : isInsideForwardRange(degree, inset: forwardEnterInset)

        isForwardLocked = nextIsForwardLocked
        updateDisplayedArrowDegree(
            to: degree,
            animated: animated
        )
    }

    private func updateDisplayedArrowDegree(to targetDegree: CGFloat, animated: Bool = true) {
        let continuousTarget = closestContinuousDegree(
            from: displayedArrowDegree,
            to: targetDegree
        )
        let update = {
            displayedArrowDegree = continuousTarget
        }

        if animated {
            withAnimation(
                .interpolatingSpring(
                    stiffness: 120,
                    damping: 12
                )
            ) {
                update()
            }
        } else {
            update()
        }
    }

    private func closestContinuousDegree(from currentDegree: CGFloat, to targetDegree: CGFloat) -> CGFloat {
        var adjustedDegree = targetDegree

        while adjustedDegree - currentDegree > 180 {
            adjustedDegree -= 360
        }

        while currentDegree - adjustedDegree > 180 {
            adjustedDegree += 360
        }

        return adjustedDegree
    }

    private func normalizedDegree(_ degree: CGFloat) -> CGFloat {
        let normalized = degree.truncatingRemainder(dividingBy: 360)

        return normalized >= 0 ? normalized : normalized + 360
    }

    private func updateArrivalState(
        isInsideArrivalRadius: Bool,
        isOutsideArrivalExitRadius: Bool
    ) {
        if isArrivalConfirmed {
            guard isOutsideArrivalExitRadius else { return }

            resetArrivalState()

            return
        }

        guard isInsideArrivalRadius else { return }

        isArrivalConfirmed = true
    }

    private func resetArrivalState() {
        isArrivalConfirmed = false
    }

    private func skipToParkingSpot() {
        store.skipToParkingSpot()
        resetArrivalState()
        updateArrivalState(
            isInsideArrivalRadius: locationManager.isInsideArrivalRadius(
                targetCoordinate: store.currentTrackingCoordinate,
                targetAccuracy: store.currentTrackingHorizontalAccuracy
            ),
            isOutsideArrivalExitRadius: locationManager.isOutsideArrivalExitRadius(
                targetCoordinate: store.currentTrackingCoordinate
            )
        )
    }

    private func advanceWaypointIfNeeded(isArrivalConfirmed: Bool) {
        guard
            isArrivalConfirmed,
            !store.isTrackingParkingSpot,
            let targetIndex = store.trackingTargetIndex
        else { return }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))

            guard
                self.isArrivalConfirmed,
                self.store.trackingTargetIndex == targetIndex,
                !self.store.isTrackingParkingSpot
            else { return }

            _ = self.store.advanceToNextTrackingTarget()
            self.resetArrivalState()
            self.updateArrivalState(
                isInsideArrivalRadius: self.locationManager.isInsideArrivalRadius(
                    targetCoordinate: self.store.currentTrackingCoordinate,
                    targetAccuracy: self.store.currentTrackingHorizontalAccuracy
                ),
                isOutsideArrivalExitRadius: self.locationManager.isOutsideArrivalExitRadius(
                    targetCoordinate: self.store.currentTrackingCoordinate
                )
            )
        }
    }
}

#Preview {
    @Previewable @StateObject var store = WaypointStore()
    @Previewable @StateObject var locationManager = UserLocationManager()

    TrackerView(store: store, locationManager: locationManager) {}
        .preferredColorScheme(.dark)
}

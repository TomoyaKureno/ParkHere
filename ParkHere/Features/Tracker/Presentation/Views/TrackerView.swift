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
    @ObservedObject var altimeterManager: AltimeterManager

    let onFoundIt: () -> Void
    
    @State private var displayedFloors = 0
    private let estimator = FloorEstimator()

    @State private var showAlert = false
    @State private var showSkipToParkingSpotAlert = false
    @State private var displayedArrowDegree: CGFloat = 0
    @State private var isForwardLocked = false
    @State private var isArrivalConfirmed = false

    private let forwardEnterInset: CGFloat = 20
    private let forwardExitInset: CGFloat = 30

    var body: some View {
        Group {
            if altimeterManager.isMotionAccessDenied {
                motionAccessDeniedView
            } else {
                trackerContent
            }
        }
        .navigationBarBackButtonHidden()
    }

    private var motionAccessDeniedView: some View {
        ZStack {
            Color.surfacePrimaryBlack
                .ignoresSafeArea()

            VStack {
                UnavailableView.motion
            }
        }
    }

    private var trackerContent: some View {
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
                trackerHeaderSection
                waypointPhotoSection
                skipToParkingPrompt
                navigationPanel
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            locationManager.requestAccessAndStartUpdating()
            locationManager.setBackgroundUpdates(true)
            altimeterManager.start()
            updateDisplayedArrowDegree(to: targetArrowDegree, animated: false)
            updateArrivalState(isInsideArrivalRadius: isInsideArrivalRadius)
        }
        .onDisappear {
            locationManager.setBackgroundUpdates(false)
            altimeterManager.stop()
        }
        .onChange(of: altimeterManager.absoluteAltitude) { _, _ in
            guard let delta = floorDeltaMeters else { return }
            displayedFloors = estimator.floors(deltaMeters: delta, previousFloors: displayedFloors)
        }
        .onChange(of: store.trackingTargetIndex) { _, _ in
            displayedFloors = 0   // reset saat target waypoint berganti
        }
        .onChange(of: isInsideArrivalRadius) { _, newValue in
            updateArrivalState(isInsideArrivalRadius: newValue)

            if !newValue {
                updateDisplayedArrowDegree(to: targetArrowDegree)
            }
        }
        .onChange(of: isArrivalConfirmed) { _, newValue in
            advanceWaypointIfNeeded(isArrivalConfirmed: newValue)
        }
        .onChange(of: directionDegree) { _, _ in
            guard !isInsideArrivalRadius else { return }

            updateDisplayedArrowDegree(to: targetArrowDegree)
        }
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

    private var directionDegree: CGFloat {
        locationManager.relativeBearing(to: store.currentTrackingCoordinate) ?? 0
    }

    private var forwardInset: CGFloat { 20 }

    private var isInsideForwardInset: Bool {
        directionDegree <= forwardInset || directionDegree >= 360 - forwardInset
    }

    private var targetArrowDegree: CGFloat {
        snappedForwardDegree(for: directionDegree, inset: forwardInset)
    }

    private var normalizedArrowDegree: CGFloat {
        normalizedDegree(displayedArrowDegree)
    }

    private var distanceText: String {
        locationManager.distanceText(to: store.currentTrackingCoordinate)
    }

    private var isInsideArrivalRadius: Bool {
        locationManager.isInsideArrivalRadius(
            targetCoordinate: store.currentTrackingCoordinate,
            targetAccuracy: store.currentTrackingHorizontalAccuracy
        )
    }

    private var isTrackingParkingSpot: Bool {
        store.isTrackingParkingSpot
    }

    private var trackerHeaderSection: some View {
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
    }

    private var waypointPhotoSection: some View {
        waypointImage
            .resizable()
            .scaledToFill()
            .frame(height: 264)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topLeading) {
                waypointPhotoLabel
            }
    }

    @ViewBuilder
    private var waypointPhotoLabel: some View {
        if isTrackingParkingSpot {
            WaypointLabel(text: "Parking Spot", color: .brandPrimaryBlue)
        } else {
            WaypointLabel(text: "\(store.remainingWaypointCount) waypoints to go", color: .brandAccentGreen)
        }
    }

    @ViewBuilder
    private var skipToParkingPrompt: some View {
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
    }

    private var navigationPanel: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            compassView
            Spacer(minLength: 0)
            statsBar
            foundItButton
        }
        .frame(maxWidth: .infinity)
        .background {
            trackerSemicircleBackground
        }
    }

    @ViewBuilder
    private var foundItButton: some View {
        if isTrackingParkingSpot, store.currentTrackingCoordinate != nil {
            Button("Found it!") {
                guard isArrivalConfirmed else { return }
                showAlert = true
            }
            .buttonStyle(.primaryStyle)
            .disabled(!isArrivalConfirmed)
        }
    }

    private var trackerBackgroundColor: Color {
        isArrivalConfirmed || isInsideArrivalRadius || isInsideForwardInset
            ? Color.brandAccentGreen
            : Color.surfaceGray
    }

    private var trackerSemicircleBackground: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let diameter = width * 3

            Circle()
                .fill(trackerBackgroundColor)
                .frame(width: diameter, height: diameter)
                .position(x: width / 2, y: diameter / 2)
        }
        .allowsHitTesting(false)
    }

    private var isArcFlipped: Bool {
        normalizedArrowDegree > 180
    }

    private var arcDegree: CGFloat {
        isArcFlipped ? 360 - normalizedArrowDegree : normalizedArrowDegree
    }

    private var arcVisibleDegree: CGFloat {
        max(0, arcDegree - forwardInset * 2)
    }

    private var arcStart: CGFloat {
        forwardInset / 360
    }

    private var arcEnd: CGFloat {
        (forwardInset + arcVisibleDegree) / 360
    }

    private var shouldHideArc: Bool {
        arcVisibleDegree <= 0
    }

    private var compassView: some View {
        ZStack(alignment: .top) {
            if isArrivalConfirmed {
                arrivalCheckmarkView
            } else {
                compassNeedleView
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
    }

    private var arrivalCheckmarkView: some View {
        Image(systemName: AppIcon.checkmark)
            .font(.system(size: 116).bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.scale.combined(with: .opacity))
    }

    private var compassNeedleView: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 16, height: 16)

            compassArcWithArrow
        }
    }

    private var compassArcWithArrow: some View {
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
                directionArrowView
            }
    }

    private var directionArrowView: some View {
        Image(systemName: AppIcon.arrowUp)
            .font(.system(size: 116).bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                compassRotatingDot
            }
            .rotationEffect(.degrees(displayedArrowDegree))
    }

    private var compassRotatingDot: some View {
        Circle()
            .fill(.gray)
            .frame(width: 16, height: 16)
            .opacity(isInsideForwardInset ? 0 : 1)
    }

    private var waypointImage: Image {
        if let currentTrackingImage = store.currentTrackingImage {
            return Image(uiImage: currentTrackingImage)
        }

        return Image("imgWaypoint")
    }
    
    private var floorDeltaMeters: Double? {
        guard
            let current = altimeterManager.absoluteAltitude,
            let anchor = store.currentTrackingAltitudeAnchor?.absoluteAltitude
        else { return nil }
        return anchor - current
    }

    private var distanceWidget: some View {
        VStack {
            Text("est.")
            HStack(spacing: 8) {
                Image(systemName: AppIcon.figureWalk)
                Text(distanceText)
            }
            .font(.largeTitle.bold())
        }
        .foregroundStyle(.white)
    }

    private var floorWidget: some View {
        VStack {
            Text("est.")
            floorValueRow
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var floorValueRow: some View {
        HStack(spacing: 8) {
            if floorDeltaMeters != nil {
                Image(systemName: estimator.icon(displayedFloors))
                Text(estimator.shortLabel(displayedFloors))
            } else {
                Text("--")
            }
        }
        .font(.largeTitle.bold())
    }

    private var statsBar: some View {
        HStack {
            Spacer()
            distanceWidget
            Spacer()
            statsBarDivider
            Spacer()
            floorWidget
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 95)
        .background(.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }

    private var statsBarDivider: some View {
        VStack {}
            .frame(width: 2)
            .frame(maxHeight: .infinity)
            .background(.gray)
            .clipShape(Capsule())
    }

    private func snappedForwardDegree(for degree: CGFloat, inset: CGFloat) -> CGFloat {
        if degree >= 360 - inset {
            return 360
        }

        if degree <= inset {
            return 0
        }

        return degree
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
    @Previewable @StateObject var altimeterManager = AltimeterManager()

    TrackerView(
        store: store,
        locationManager: locationManager,
        altimeterManager: altimeterManager
    ) {}
    .preferredColorScheme(.dark)
}

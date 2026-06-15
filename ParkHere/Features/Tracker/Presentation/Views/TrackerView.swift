//
//  TrackerView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 05/06/26.
//

import CoreLocation
import SwiftUI

struct TrackerView: View {
    @ObservedObject var store: WaypointStore
    @ObservedObject var locationManager: UserLocationManager
    @ObservedObject var altimeterManager: AltimeterManager

    let onFoundIt: () -> Void
    let onTapBack: () -> Void
    let onTapLandmarks: (Bool) -> Void

    @State private var displayedFloors = 0
    private let estimator = FloorEstimator()

    @State private var showAlert = false
    @State private var showSkipToParkingSpotAlert = false
    @State private var displayedArrowDegree: CGFloat = 0
    @State private var arrivalEnteredAt: Date?
    @State private var isArrivalConfirmed = false
    @State private var isPreparingTrackingLocation = true
    @State private var hasPreparedCurrentLocation = false
    @State private var hasPreparedTrackingLocation = false
    @State private var trackingLocationFailed = false
    @State private var didRequestInitialTrackingLocation = false

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
        GeometryReader { geo in
            let safeWidth = safeDimension(geo.size.width)
            let safeHeight = safeDimension(geo.size.height)
            let bottomSafeAreaInset = safeDimension(geo.safeAreaInsets.bottom)
            let overlayHeight = safeHeight * 0.5
            let imageHeight = safeHeight * 0.6
            let indicatorWidth = max(1, (safeWidth / 2) - 1)

            ZStack {
                Color.surfacePrimaryBlack
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    waypointImage
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: safeWidth,
                            height: imageHeight + bottomSafeAreaInset
                        )
                        .clipped()
                        .offset(y: bottomSafeAreaInset)
                }

                VStack {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.82),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(maxHeight: overlayHeight)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack {
                    VStack(spacing: 24) {
                        HStack(spacing: 0) {
                            VStack {
                                Text("est.")

                                HStack(spacing: 8) {
                                    Image(systemName: AppIcon.figureWalk)
                                    Text(distanceText)
                                }
                                .font(.title.bold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: indicatorWidth)

                            VStack {}
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                                .background(.gray)
                                .clipShape(Capsule())

                            VStack {
                                Text("est.")

                                floorValueRow
                                    .font(.title.bold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: indicatorWidth)
                        }
                        .frame(maxHeight: 64)

                        Text(directionGuideText)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)

                        arrowWaypoint
                    }
                    .padding(.vertical, 16)

                    Spacer()

                    VStack(spacing: 16) {
                        HStack {
                            VStack(spacing: 8) {
                                Text("You're now heading to")
                                    .font(.headline)
                                
                                Button {
                                    onTapLandmarks(false)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(store.currentTrackingTitle)
                                            .font(.title.bold())
                                        Text(store.currentTrackingProgressText)
                                            .font(.subheadline)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 24)
                                }
                                .glassEffect(.regular, in: Capsule())
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)

                        if true {
                            foundItButton
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isPreparingTrackingLocation || trackingLocationFailed {
                    trackingPreparationOverlay
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
        }
        .onAppear {
            locationManager.requestAccessAndStartUpdating()
            locationManager.setBackgroundUpdates(true)
            altimeterManager.start()
            prepareInitialTrackingLocationIfNeeded()
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
            displayedFloors = 0
            resetArrivalState()

            guard hasPreparedTrackingLocation else { return }

            updateDisplayedArrowDegree(to: targetArrowDegree, animated: false)
            updateArrivalState(isInsideArrivalRadius: isInsideArrivalRadius)
        }
        .onChange(of: isInsideArrivalRadius) { _, newValue in
            guard hasPreparedTrackingLocation else { return }

            updateArrivalState(isInsideArrivalRadius: newValue)

            if !newValue {
                updateDisplayedArrowDegree(to: targetArrowDegree)
            }
        }
        .onChange(of: isArrivalConfirmed) { _, newValue in
            guard hasPreparedTrackingLocation else { return }

            advanceWaypointIfNeeded(isArrivalConfirmed: newValue)
        }
        .onChange(of: directionDegree) { _, _ in
            guard hasPreparedTrackingLocation, !isInsideArrivalRadius else { return }

            updateDisplayedArrowDegree(to: targetArrowDegree)
        }
        .onChange(of: locationManager.heading?.headingAccuracy) { _, _ in
            completeInitialTrackingPreparationIfReady()
        }
        .onChange(of: locationManager.needsHeadingCalibration) { _, _ in
            completeInitialTrackingPreparationIfReady()
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

    private var hasDirection: Bool {
        locationManager.relativeBearing(to: store.currentTrackingCoordinate) != nil
    }

    private var forwardInset: CGFloat {
        20
    }

    private var isInsideForwardInset: Bool {
        angularDistance(from: directionDegree, to: 0) <= forwardAlignmentInset
    }

    private var forwardAlignmentInset: CGFloat {
        forwardInset + targetRadiusBearingAllowance
    }

    private var targetRadiusBearingAllowance: CGFloat {
        guard
            let distance = locationManager.distance(to: store.currentTrackingCoordinate),
            distance > 0
        else { return 0 }

        let arrivalRadius = locationManager.arrivalRadius(
            targetAccuracy: store.currentTrackingHorizontalAccuracy
        )

        guard distance > arrivalRadius else { return 180 }

        let radiusRatio = min(arrivalRadius / distance, 1)
        let allowance = asin(radiusRatio) * 180 / .pi

        return min(CGFloat(allowance), 60)
    }

    private var targetArrowDegree: CGFloat {
        directionDegree
    }

    private var normalizedArrowDegree: CGFloat {
        normalizedDegree(displayedArrowDegree)
    }

    private var directionGuideText: String {
        guard hasDirection else {
            return "Getting your direction"
        }

        if isArrivalConfirmed {
            return isTrackingParkingSpot ? "Parking spot found" : "Landmark found"
        }

        if angularDistance(from: normalizedArrowDegree, to: 0) <= forwardAlignmentInset {
            return "Walk straight to align the circles"
        }

        switch normalizedArrowDegree {
        case 20..<160:
            return "Turn and walk right to align the circles"
        case 160...200:
            return "Turn around to align the circles"
        case 200..<340:
            return "Turn and walk left to align the circles"
        default:
            return "Walk straight to align the circles"
        }
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

    private var trackerBackgroundColor: Color {
        isArrivalConfirmed || isInsideArrivalRadius || isInsideForwardInset
            ? Color.brandAccentGreen
            : Color.surfaceGray
    }

    private var isArcFlipped: Bool {
        normalizedArrowDegree > 180
    }

    private var arcDegree: CGFloat {
        isArcFlipped ? 360 - normalizedArrowDegree : normalizedArrowDegree
    }

    private var arcVisibleDegree: CGFloat {
        max(0, arcDegree - forwardAlignmentInset * 2)
    }

    private var arcStart: CGFloat {
        forwardAlignmentInset / 360
    }

    private var arcEnd: CGFloat {
        (forwardAlignmentInset + arcVisibleDegree) / 360
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

    private var arrowWaypoint: some View {
        ZStack(alignment: .top) {
            if isArrivalConfirmed {
                arrivalCheckmarkView
            } else {
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .opacity(isInsideForwardInset ? 0 : 1)

                compassArcWithArrow
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
                .opacity(isInsideForwardInset ? 0 : 1)

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
            .fill(isInsideForwardInset ? .white : .gray)
            .frame(width: 16, height: 16)
    }

    private var waypointImage: Image {
        if let currentTrackingImage = store.currentTrackingImage {
            return Image(uiImage: currentTrackingImage)
        }

        return Image("imgWaypoint")
    }

    private var floorDeltaMeters: Double? {
        guard let anchor = store.currentTrackingAltitudeAnchor else { return nil }

        if let current = altimeterManager.absoluteAltitude,
           let anchorAltitude = anchor.absoluteAltitude
        {
            return anchorAltitude - current
        }

        if let current = altimeterManager.relativeAltitude,
           let anchorAltitude = anchor.relativeAltitude
        {
            return anchorAltitude - current
        }

        return nil
    }

    private var floorValueRow: some View {
        HStack(spacing: 8) {
            if floorDeltaMeters != nil {
                Image(systemName: estimator.icon(displayedFloors))
                Text(estimator.shortLabel(displayedFloors))
            } else {
                Text("--")
            }
        }
    }

    private var foundItButton: some View {
        Button {
            showAlert = true
        } label: {
            Text("Found it!")
        }
        .buttonStyle(.primaryStyle)
    }

    @ViewBuilder
    private var trackingPreparationOverlay: some View {
        if trackingLocationFailed {
            UnavailableView(
                opacity: 0.96,
                systemImage: AppIcon.locationSlash,
                title: "Current Location Unavailable",
                subtitle: "Turn on location access or move to an area with a better signal to start tracking.",
                buttonTitle: "Back to Home",
                buttonAction: onFoundIt
            )
        } else {
            ZStack {
                Color.surfacePrimaryBlack
                    .opacity(0.96)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)

                    Text("Getting your current location")
                        .font(.title3Bold)
                        .foregroundStyle(.white)

                    Text("Move your iPhone in a figure 8 to calibrate the compass. We’ll start guiding you once your location and compass are ready.")
                        .font(.subheadlineReg)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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

    private func angularDistance(from sourceDegree: CGFloat, to targetDegree: CGFloat) -> CGFloat {
        let source = normalizedDegree(sourceDegree)
        let target = normalizedDegree(targetDegree)
        let difference = abs(source - target)

        return min(difference, 360 - difference)
    }

    private func safeDimension(_ value: CGFloat) -> CGFloat {
        guard value.isFinite, value > 0 else { return 0 }

        return value
    }

    private func prepareInitialTrackingLocationIfNeeded() {
        guard !didRequestInitialTrackingLocation else { return }

        didRequestInitialTrackingLocation = true
        isPreparingTrackingLocation = true
        hasPreparedCurrentLocation = false
        hasPreparedTrackingLocation = false
        trackingLocationFailed = false

        locationManager.requestCurrentLocation { location in
            let trackingLocation = location ?? locationManager.currentLocation
            let hasUsableLocation = trackingLocation != nil || locationManager.hasUsableLocation

            guard hasUsableLocation else {
                hasPreparedTrackingLocation = false
                isPreparingTrackingLocation = false
                trackingLocationFailed = true

                return
            }

            store.prepareTracking(from: trackingLocation)
            hasPreparedCurrentLocation = true
            completeInitialTrackingPreparationIfReady()
        }
    }

    private func completeInitialTrackingPreparationIfReady() {
        guard isPreparingTrackingLocation else { return }
        guard hasPreparedCurrentLocation else { return }
        guard locationManager.isHeadingCalibratedForTracking else { return }

        hasPreparedTrackingLocation = true
        trackingLocationFailed = false
        isPreparingTrackingLocation = false
        updateDisplayedArrowDegree(to: targetArrowDegree, animated: false)
        updateArrivalState(isInsideArrivalRadius: isInsideArrivalRadius)
    }

    private func updateArrivalState(isInsideArrivalRadius: Bool) {
        guard isInsideArrivalRadius else {
            resetArrivalState()

            return
        }

        guard arrivalEnteredAt == nil else { return }

        let enteredAt = Date()
        arrivalEnteredAt = enteredAt

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard arrivalEnteredAt == enteredAt else { return }

            isArrivalConfirmed = true
        }
    }

    private func resetArrivalState() {
        arrivalEnteredAt = nil
        isArrivalConfirmed = false
    }

    private func skipToParkingSpot() {
        store.skipToParkingSpot()
        resetArrivalState()
        updateArrivalState(
            isInsideArrivalRadius: locationManager.isInsideArrivalRadius(
                targetCoordinate: store.currentTrackingCoordinate,
                targetAccuracy: store.currentTrackingHorizontalAccuracy
            )
        )
    }

    private func advanceWaypointIfNeeded(isArrivalConfirmed: Bool) {
        guard
            isArrivalConfirmed,
            !store.isTrackingParkingSpot,
            let targetIndex = store.trackingTargetIndex
        else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
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
    ) {} onTapBack: {} onTapLandmarks: { _ in
    }
    .preferredColorScheme(.dark)
}

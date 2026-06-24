//
//  TrackerViewModel.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 18/06/26.
//

import Combine
import CoreLocation
import SwiftUI

@MainActor
final class TrackerViewModel: ObservableObject {
    @Published var displayedFloors = 0
    @Published var showAlert = false
    @Published var displayedArrowDegree: CGFloat = 0
    @Published var isArrivalConfirmed = false
    @Published var isPreparingTrackingLocation = true
    @Published var trackingLocationFailed = false
    @Published var rerouteCandidate: LandmarkRerouteCandidate?
    @Published var isShowingRerouteAnimation = false

    private let store: LandmarkStore
    private let locationManager: UserLocationManager
    private let altimeterManager: AltimeterManager
    private let estimator = FloorEstimator()
    private let minimumRerouteSavedDistance: CLLocationDistance = 10

    private var arrivalEnteredAt: Date?
    private var hasPreparedCurrentLocation = false
    private var hasPreparedTrackingLocation = false
    private var didRequestInitialTrackingLocation = false
    private var dismissedReroutePromptKey: ReroutePromptKey?

    init(
        store: LandmarkStore,
        locationManager: UserLocationManager,
        altimeterManager: AltimeterManager
    ) {
        self.store = store
        self.locationManager = locationManager
        self.altimeterManager = altimeterManager
    }

    var directionDegree: CGFloat {
        locationManager.relativeBearing(to: store.currentTrackingCoordinate) ?? 0
    }

    var hasDirection: Bool {
        locationManager.relativeBearing(to: store.currentTrackingCoordinate) != nil
    }

    var forwardAlignmentInset: CGFloat {
        32
    }

    var arcInsetDegree: CGFloat {
        24
    }

    var isInsideForwardInset: Bool {
        angularDistance(from: directionDegree, to: 0) <= forwardAlignmentInset
    }

    var shouldHideDirectionDots: Bool {
        isInsideArrivalRadius
    }

    var targetArrowDegree: CGFloat {
        return forwardPulledDegree(from: directionDegree)
    }

    var normalizedArrowDegree: CGFloat {
        normalizedDegree(displayedArrowDegree)
    }

    var directionGuideText: String {
        guard hasDirection else {
            return "Getting your direction"
        }

        if isArrivalConfirmed {
            return isTrackingParkingSpot ? "Parking spot found" : "Landmark found"
        }

        if isShowingRerouteAnimation {
            return "Route updated"
        }

        if isInsideArrivalRadius {
            return "You're already near to the \(trackingTargetLocationText). Take a look around"
        }

        if isInsideForwardInset {
            return "Great! You're heading the right direction. Keep following the arrow"
        }

        return "Match the grey dots with the white dots to face the correct direction"
    }

    var distanceText: String {
        locationManager.distanceText(to: store.currentTrackingCoordinate)
    }

    var isInsideArrivalRadius: Bool {
        locationManager.isInsideArrivalRadius(
            targetCoordinate: store.currentTrackingCoordinate,
            targetAccuracy: store.currentTrackingHorizontalAccuracy
        )
    }

    var isInsideArrivalTarget: Bool {
        guard isInsideArrivalRadius else { return false }

        return isSameTargetAltitude
    }

    var isSameTargetAltitude: Bool {
        guard let targetFloors else { return false }

        return targetFloors == 0
    }

    var targetFloors: Int? {
        guard let delta = floorDeltaMeters else { return nil }

        return estimator.floors(deltaMeters: delta, previousFloors: displayedFloors)
    }

    var isTrackingParkingSpot: Bool {
        store.isTrackingParkingSpot
    }

    var trackingTargetLocationText: String {
        isTrackingParkingSpot ? "parking location" : "landmark"
    }

    var shouldShowParkingFoundButton: Bool {
        isTrackingParkingSpot
    }

    var isArcFlipped: Bool {
        normalizedArrowDegree > 180
    }

    var arcDegree: CGFloat {
        isArcFlipped ? 360 - normalizedArrowDegree : normalizedArrowDegree
    }

    var arcVisibleDegree: CGFloat {
        max(0, arcDegree - arcInsetDegree * 2)
    }

    var arcStart: CGFloat {
        arcInsetDegree / 360
    }

    var arcEnd: CGFloat {
        (arcInsetDegree + arcVisibleDegree) / 360
    }

    var shouldHideArc: Bool {
        arcVisibleDegree <= 0
    }

    var floorDeltaMeters: Double? {
        floorDeltaMeters(to: store.currentTrackingAltitudeAnchor)
    }

    var floorIcon: String {
        estimator.icon(displayedFloors)
    }

    var floorShortLabel: String {
        estimator.shortLabel(displayedFloors)
    }

    func onAppear() {
        locationManager.requestAccessAndStartUpdating()
        locationManager.setBackgroundUpdates(true)
        altimeterManager.start()
        prepareInitialTrackingLocationIfNeeded()
    }

    func onDisappear() {
        locationManager.setBackgroundUpdates(false)
        altimeterManager.stop()
    }

    func handleTrackingTargetChanged() {
        displayedFloors = 0
        rerouteCandidate = nil
        dismissedReroutePromptKey = nil
        resetArrivalState()

        guard hasPreparedTrackingLocation else { return }

        updateDisplayedArrowDegree(to: targetArrowDegree, animated: false)
        updateArrivalState(isInsideArrivalTarget: isInsideArrivalTarget)
    }

    func handleArrivalRadiusChanged() {
        guard hasPreparedTrackingLocation else { return }

        updateArrivalState(isInsideArrivalTarget: isInsideArrivalTarget)

        if !isInsideArrivalTarget {
            updateDisplayedArrowDegree(to: targetArrowDegree)
        }
    }

    func handleArrivalConfirmationChanged(_ isArrivalConfirmed: Bool) {
        guard hasPreparedTrackingLocation else { return }

        advanceLandmarkIfNeeded(isArrivalConfirmed: isArrivalConfirmed)
    }

    func handleDirectionChanged() {
        guard hasPreparedTrackingLocation, !isInsideArrivalTarget else { return }

        updateDisplayedArrowDegree(to: targetArrowDegree)
    }

    func finishFoundCar(onFoundIt: () -> Void) {
        store.clearParkingSpot()
        resetArrivalState()
        onFoundIt()
    }

    func updateDisplayedFloorsAndArrival() {
        guard let targetFloors else { return }

        displayedFloors = targetFloors

        guard hasPreparedTrackingLocation else { return }

        updateArrivalState(isInsideArrivalTarget: isInsideArrivalTarget)
        updateDisplayedArrowDegree(to: targetArrowDegree)
        evaluateRerouteCandidateIfNeeded()
    }

    func completeInitialTrackingPreparationIfReady() {
        guard isPreparingTrackingLocation else { return }
        guard hasPreparedCurrentLocation else { return }
        guard locationManager.isHeadingCalibratedForTracking else { return }

        hasPreparedTrackingLocation = true
        trackingLocationFailed = false
        isPreparingTrackingLocation = false
        updateDisplayedArrowDegree(to: targetArrowDegree, animated: false)
        updateArrivalState(isInsideArrivalTarget: isInsideArrivalTarget)
    }

    func evaluateRerouteCandidateIfNeeded() {
        guard
            hasPreparedTrackingLocation,
            !isPreparingTrackingLocation,
            !trackingLocationFailed,
            !isArrivalConfirmed,
            !isInsideArrivalTarget,
            !isShowingRerouteAnimation,
            rerouteCandidate == nil
        else { return }

        guard let candidate = store.nearestRerouteCandidate(
            from: locationManager.currentLocation,
            minimumSavedDistance: minimumRerouteSavedDistance,
            isSameFloor: isSameFloorWithCurrentUser
        ) else { return }

        let promptKey = ReroutePromptKey(
            currentTargetIndex: store.trackingTargetIndex,
            candidateIndex: candidate.index
        )

        guard dismissedReroutePromptKey != promptKey else { return }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
            rerouteCandidate = candidate
        }
    }

    func dismissRerouteCandidate() {
        guard let rerouteCandidate else { return }

        dismissedReroutePromptKey = ReroutePromptKey(
            currentTargetIndex: store.trackingTargetIndex,
            candidateIndex: rerouteCandidate.index
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            self.rerouteCandidate = nil
        }
    }

    func confirmRerouteCandidate() {
        guard let rerouteCandidate else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            self.rerouteCandidate = nil
        }

        resetArrivalState()
        isShowingRerouteAnimation = true
        store.rerouteTracking(to: rerouteCandidate.index)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            isShowingRerouteAnimation = false
            updateDisplayedArrowDegree(to: targetArrowDegree, animated: false)
            updateArrivalState(isInsideArrivalTarget: isInsideArrivalTarget)
            evaluateRerouteCandidateIfNeeded()
        }
    }

    func safeDimension(_ value: CGFloat) -> CGFloat {
        guard value.isFinite, value > 0 else { return 0 }

        return value
    }

    private func updateDisplayedArrowDegree(to targetDegree: CGFloat, animated: Bool = true) {
        let continuousTarget = closestContinuousDegree(
            from: displayedArrowDegree,
            to: targetDegree
        )
        let update = {
            self.displayedArrowDegree = continuousTarget
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

    private func signedForwardOffset(from degree: CGFloat) -> CGFloat {
        let normalized = normalizedDegree(degree)

        return normalized > 180 ? normalized - 360 : normalized
    }

    private func forwardPulledDegree(from degree: CGFloat) -> CGFloat {
        let signedOffset = signedForwardOffset(from: degree)
        guard abs(signedOffset) <= forwardAlignmentInset else { return degree }

        return signedOffset * (1 - 0.55)
    }

    private func prepareInitialTrackingLocationIfNeeded() {
        guard !didRequestInitialTrackingLocation else { return }

        didRequestInitialTrackingLocation = true
        isPreparingTrackingLocation = true
        hasPreparedCurrentLocation = false
        hasPreparedTrackingLocation = false
        trackingLocationFailed = false

        locationManager.requestCurrentLocation { [weak self] location in
            guard let self else { return }

            let trackingLocation = location ?? locationManager.currentLocation
            let hasUsableLocation = trackingLocation != nil || locationManager.hasUsableLocation

            guard hasUsableLocation else {
                hasPreparedTrackingLocation = false
                isPreparingTrackingLocation = false
                trackingLocationFailed = true

                return
            }

            store.prepareTracking(from: trackingLocation) { [weak self] landmark in
                self?.floorsFromCurrentUser(to: landmark.altitude)
            }
            hasPreparedCurrentLocation = true
            completeInitialTrackingPreparationIfReady()
        }
    }

    private func updateArrivalState(isInsideArrivalTarget: Bool) {
        guard isInsideArrivalTarget else {
            resetArrivalState()

            return
        }

        guard arrivalEnteredAt == nil else { return }

        let enteredAt = Date.now
        arrivalEnteredAt = enteredAt

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard arrivalEnteredAt == enteredAt else { return }

            isArrivalConfirmed = true
        }
    }

    private func resetArrivalState() {
        arrivalEnteredAt = nil
        isArrivalConfirmed = false
    }

    private func isSameFloorWithCurrentUser(_ landmark: ParkingLandmark) -> Bool {
        guard let floors = floorsFromCurrentUser(to: landmark.altitude) else { return false }

        return floors == 0
    }

    private func floorsFromCurrentUser(to anchor: AltitudeSample?) -> Int? {
        guard let delta = floorDeltaMeters(to: anchor) else { return nil }

        return estimator.floors(deltaMeters: delta, previousFloors: 0)
    }

    private func floorDeltaMeters(to anchor: AltitudeSample?) -> Double? {
        guard let anchor else { return nil }

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

    private func advanceLandmarkIfNeeded(isArrivalConfirmed: Bool) {
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
                isInsideArrivalTarget: self.isInsideArrivalTarget
            )
        }
    }
}

private struct ReroutePromptKey: Equatable {
    let currentTargetIndex: Int?
    let candidateIndex: Int
}

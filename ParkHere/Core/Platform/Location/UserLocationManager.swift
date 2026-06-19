//
//  UserLocationManager.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 09/06/26.
//

import Combine
import CoreLocation
import Foundation

@MainActor
final class UserLocationManager: NSObject, ObservableObject {
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var heading: CLHeading?
    @Published private(set) var statusText = "Getting current location"
    @Published private(set) var isRequestingLocation = false
    @Published private(set) var needsHeadingCalibration = false
    @Published private(set) var currentLandmark = CurrentLandmark.loading

    private let locationManager = CLLocationManager()
    private let landmarkResolver = CurrentLandmarkResolver()
    private let displayedDistanceStep: CLLocationDistance = 1
    private let targetArrivalRadius: CLLocationDistance = 5
    private let targetExitRadius: CLLocationDistance = 8
    private let captureDesiredAccuracy: CLLocationAccuracy = 5
    private let captureLocationTimeout: TimeInterval = 3
    private let reusableLocationMaximumAge: TimeInterval = 5
    private let headingCalibrationShowAccuracyThreshold: CLLocationDirection = 35
    private let headingCalibrationHideAccuracyThreshold: CLLocationDirection = 20
    private let headingCalibrationRequiredBadUpdates = 3
    private let headingCalibrationRequiredGoodUpdates = 2
    private let landmarkRefreshDistance: CLLocationDistance = 50
    private let trackingSmoothingFactor = 0.45
    private var pendingLocationCompletion: ((CLLocation?) -> Void)?
    private var pendingBestCaptureLocation: CLLocation?
    private var pendingCaptureLocationTask: Task<Void, Never>?
    private var latestRawLocation: CLLocation?
    private var lastLandmarkLocation: CLLocation?
    private var landmarkLookupTask: Task<Void, Never>?
    private var poorHeadingUpdateCount = 0
    private var goodHeadingUpdateCount = 0

    var hasUsableLocation: Bool {
        latestRawLocation != nil || currentLocation != nil
    }

    var currentCaptureLocation: CLLocation? {
        recentLocation(latestRawLocation) ?? recentLocation(currentLocation)
    }

    var isHeadingCalibratedForTracking: Bool {
        guard let heading else { return false }

        let accuracy = heading.headingAccuracy

        return accuracy >= 0
            && accuracy <= headingCalibrationHideAccuracyThreshold
            && !needsHeadingCalibration
    }

    override init() {
        authorizationStatus = locationManager.authorizationStatus

        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = 1
        locationManager.activityType = .otherNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func requestAccessAndStartUpdating() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            updateAuthorizationStatus(status)
        }
    }

    func requestCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        pendingCaptureLocationTask?.cancel()
        pendingBestCaptureLocation = bestCaptureLocation(
            pendingBestCaptureLocation,
            comparedTo: recentLocation(latestRawLocation)
        )

        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            pendingLocationCompletion = completion
            isRequestingLocation = true
            statusText = "Getting current location"
            startCaptureLocationTimeout()
            locationManager.requestLocation()

        case .notDetermined:
            pendingLocationCompletion = completion
            isRequestingLocation = true
            statusText = "Waiting for location permission"
            locationManager.requestWhenInUseAuthorization()

        case .denied, .restricted:
            statusText = "Location permission is off"
            isRequestingLocation = false
            completion(nil)

        @unknown default:
            statusText = "Location permission is unavailable"
            isRequestingLocation = false
            completion(nil)
        }
    }

    func relativeBearing(to targetCoordinate: CLLocationCoordinate2D?) -> CGFloat? {
        guard
            let currentCoordinate = currentLocation?.coordinate,
            let targetCoordinate
        else { return nil }

        let targetBearing = bearing(from: currentCoordinate, to: targetCoordinate)
        let deviceHeading = heading?.trueHeading ?? heading?.magneticHeading

        guard let deviceHeading, deviceHeading >= 0 else {
            return CGFloat(targetBearing)
        }

        return CGFloat(normalizedDegrees(targetBearing - deviceHeading))
    }

    func distanceText(to targetCoordinate: CLLocationCoordinate2D?) -> String {
        guard let distance = distance(to: targetCoordinate) else { return "-- m" }

        if distance >= 1_000 {
            let kilometers = distance / 1_000
            return "\(kilometers.formatted(.number.precision(.fractionLength(1)))) km"
        }

        let roundedDistance = Int((distance / displayedDistanceStep).rounded() * displayedDistanceStep)

        return "\(max(roundedDistance, 0)) m"
    }

    func distance(to targetCoordinate: CLLocationCoordinate2D?) -> CLLocationDistance? {
        guard
            let navigationLocation = latestRawLocation ?? currentLocation,
            let targetCoordinate
        else { return nil }

        let targetLocation = CLLocation(
            latitude: targetCoordinate.latitude,
            longitude: targetCoordinate.longitude
        )

        return navigationLocation.distance(from: targetLocation)
    }

    func isInsideArrivalRadius(targetCoordinate: CLLocationCoordinate2D?) -> Bool {
        isInsideArrivalRadius(targetCoordinate: targetCoordinate, targetAccuracy: nil)
    }

    func isInsideArrivalRadius(
        targetCoordinate: CLLocationCoordinate2D?,
        targetAccuracy: CLLocationAccuracy?
    ) -> Bool {
        guard let distance = distance(to: targetCoordinate) else { return false }

        return distance <= arrivalRadius(targetAccuracy: targetAccuracy)
    }

    func arrivalRadius(targetAccuracy: CLLocationAccuracy?) -> CLLocationDistance {
        let currentAccuracy = validAccuracy(currentLocation?.horizontalAccuracy)
        let targetAccuracy = validAccuracy(targetAccuracy)
        let accuracyPadding = min((currentAccuracy + targetAccuracy) * 0.25, 8)

        return targetArrivalRadius + accuracyPadding
    }
    
    func setBackgroundUpdates(_ enabled: Bool) {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            return
        }
        locationManager.allowsBackgroundLocationUpdates = enabled
        locationManager.pausesLocationUpdatesAutomatically = !enabled
    }

    private func updateAuthorizationStatus(_ status: CLAuthorizationStatus) {
        authorizationStatus = status

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            statusText = "Location data saves automatically"
            locationManager.startUpdatingLocation()
            startHeadingUpdatesIfAvailable()

            if pendingLocationCompletion != nil {
                startCaptureLocationTimeout()
                locationManager.requestLocation()
            }

        case .notDetermined:
            statusText = "Waiting for location permission"

        case .denied, .restricted:
            statusText = "Location permission is off"
            completeCurrentLocationRequest(with: nil)

        @unknown default:
            statusText = "Location permission is unavailable"
            completeCurrentLocationRequest(with: nil)
        }
    }

    private func startHeadingUpdatesIfAvailable() {
        guard CLLocationManager.headingAvailable() else { return }

        locationManager.startUpdatingHeading()
    }

    private func handleUpdatedLocations(_ locations: [CLLocation]) {
        guard let latestLocation = locations.last(where: { isUsableLocation($0) }) else {
            return
        }

        latestRawLocation = latestLocation
        currentLocation = smoothedLocation(from: currentLocation, to: latestLocation)
        statusText = "Location data saves automatically"
        updateCurrentLandmarkIfNeeded(for: latestLocation)
        updatePendingCaptureLocation(with: latestLocation)
    }

    private func completeCurrentLocationRequest(with location: CLLocation?) {
        pendingCaptureLocationTask?.cancel()
        pendingCaptureLocationTask = nil

        guard let completion = pendingLocationCompletion else {
            isRequestingLocation = false
            pendingBestCaptureLocation = nil
            return
        }

        pendingLocationCompletion = nil
        pendingBestCaptureLocation = nil
        isRequestingLocation = false
        completion(location)
    }

    private func startCaptureLocationTimeout() {
        let timeoutInMilliseconds = Int(captureLocationTimeout * 1_000)

        pendingCaptureLocationTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(timeoutInMilliseconds))
            guard let self, pendingLocationCompletion != nil else { return }

            completeCurrentLocationRequest(
                with: pendingBestCaptureLocation ?? recentLocation(latestRawLocation)
            )
        }
    }

    private func updatePendingCaptureLocation(with location: CLLocation) {
        guard pendingLocationCompletion != nil else { return }

        pendingBestCaptureLocation = bestCaptureLocation(
            pendingBestCaptureLocation,
            comparedTo: location
        )

        guard location.horizontalAccuracy <= captureDesiredAccuracy else { return }

        completeCurrentLocationRequest(with: location)
    }

    private func bestCaptureLocation(
        _ currentBestLocation: CLLocation?,
        comparedTo candidateLocation: CLLocation?
    ) -> CLLocation? {
        guard
            let candidateLocation,
            candidateLocation.horizontalAccuracy >= 0
        else { return currentBestLocation }

        guard let currentBestLocation else { return candidateLocation }

        return candidateLocation.horizontalAccuracy < currentBestLocation.horizontalAccuracy
            ? candidateLocation
            : currentBestLocation
    }

    private func recentLocation(_ location: CLLocation?) -> CLLocation? {
        guard
            let location,
            isUsableLocation(location),
            abs(location.timestamp.timeIntervalSinceNow) <= reusableLocationMaximumAge
        else { return nil }

        return location
    }

    private func isUsableLocation(_ location: CLLocation) -> Bool {
        location.horizontalAccuracy >= 0
    }

    private func validAccuracy(_ accuracy: CLLocationAccuracy?) -> CLLocationAccuracy {
        guard let accuracy, accuracy > 0 else { return 0 }

        return accuracy
    }

    private func updateCurrentLandmarkIfNeeded(for location: CLLocation) {
        if let lastLandmarkLocation, location.distance(from: lastLandmarkLocation) < landmarkRefreshDistance {
            return
        }

        lastLandmarkLocation = location
        landmarkLookupTask?.cancel()
        landmarkLookupTask = Task { @MainActor [weak self] in
            await self?.updateCurrentLandmark(near: location)
        }
    }

    private func updateCurrentLandmark(near location: CLLocation) async {
        currentLandmark = await landmarkResolver.landmark(near: location)
    }

    private func updateHeadingCalibrationState(with heading: CLHeading) {
        let accuracy = heading.headingAccuracy
        let hasPoorAccuracy = accuracy < 0 || accuracy > headingCalibrationShowAccuracyThreshold
        let hasGoodAccuracy = accuracy >= 0 && accuracy <= headingCalibrationHideAccuracyThreshold

        if needsHeadingCalibration {
            goodHeadingUpdateCount = hasGoodAccuracy ? goodHeadingUpdateCount + 1 : 0

            guard goodHeadingUpdateCount >= headingCalibrationRequiredGoodUpdates else { return }

            needsHeadingCalibration = false
            poorHeadingUpdateCount = 0
            goodHeadingUpdateCount = 0
        } else {
            poorHeadingUpdateCount = hasPoorAccuracy ? poorHeadingUpdateCount + 1 : 0

            guard poorHeadingUpdateCount >= headingCalibrationRequiredBadUpdates else { return }

            needsHeadingCalibration = true
            poorHeadingUpdateCount = 0
            goodHeadingUpdateCount = 0
        }
    }

    private func smoothedLocation(
        from currentLocation: CLLocation?,
        to newLocation: CLLocation
    ) -> CLLocation {
        guard let currentLocation else { return newLocation }

        let currentCoordinate = currentLocation.coordinate
        let newCoordinate = newLocation.coordinate
        let smoothedCoordinate = CLLocationCoordinate2D(
            latitude: currentCoordinate.latitude + (newCoordinate.latitude - currentCoordinate.latitude) * trackingSmoothingFactor,
            longitude: currentCoordinate.longitude + (newCoordinate.longitude - currentCoordinate.longitude) * trackingSmoothingFactor
        )

        return CLLocation(
            coordinate: smoothedCoordinate,
            altitude: newLocation.altitude,
            horizontalAccuracy: newLocation.horizontalAccuracy,
            verticalAccuracy: newLocation.verticalAccuracy,
            course: newLocation.course,
            speed: newLocation.speed,
            timestamp: newLocation.timestamp
        )
    }

    private func bearing(
        from sourceCoordinate: CLLocationCoordinate2D,
        to targetCoordinate: CLLocationCoordinate2D
    ) -> Double {
        let sourceLatitude = sourceCoordinate.latitude * .pi / 180
        let sourceLongitude = sourceCoordinate.longitude * .pi / 180
        let targetLatitude = targetCoordinate.latitude * .pi / 180
        let targetLongitude = targetCoordinate.longitude * .pi / 180
        let longitudeDelta = targetLongitude - sourceLongitude

        let y = sin(longitudeDelta) * cos(targetLatitude)
        let x = cos(sourceLatitude) * sin(targetLatitude)
            - sin(sourceLatitude) * cos(targetLatitude) * cos(longitudeDelta)

        return normalizedDegrees(atan2(y, x) * 180 / .pi)
    }

    private func normalizedDegrees(_ degrees: Double) -> Double {
        let normalized = degrees.truncatingRemainder(dividingBy: 360)

        return normalized >= 0 ? normalized : normalized + 360
    }

}

extension UserLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            updateAuthorizationStatus(manager.authorizationStatus)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        Task { @MainActor in
            handleUpdatedLocations(locations)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            heading = newHeading
            updateHeadingCalibrationState(with: newHeading)
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        false
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            statusText = "Location unavailable"
            completeCurrentLocationRequest(with: nil)
        }
    }
}

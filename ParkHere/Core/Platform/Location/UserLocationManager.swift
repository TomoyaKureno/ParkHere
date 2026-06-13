//
//  UserLocationManager.swift
//  ParkHere
//
//  Created by Codex on 09/06/26.
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

    private let locationManager = CLLocationManager()
    private let displayedDistanceStep: CLLocationDistance = 5
    private let targetArrivalRadius: CLLocationDistance = 3
    private let targetExitRadius: CLLocationDistance = 5
    private let captureDesiredAccuracy: CLLocationAccuracy = 5
    private let captureLocationTimeout: TimeInterval = 3
    private let reusableLocationMaximumAge: TimeInterval = 5
    private let trackingSmoothingFactor = 0.45
    private var pendingLocationCompletion: ((CLLocation?) -> Void)?
    private var pendingBestCaptureLocation: CLLocation?
    private var pendingCaptureLocationTask: Task<Void, Never>?
    private var latestRawLocation: CLLocation?

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
        updateAuthorizationStatus(locationManager.authorizationStatus)
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
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

    func arrivalRadius(targetAccuracy: CLLocationAccuracy?) -> CLLocationDistance {
        targetArrivalRadius
    }

    func isInsideArrivalRadius(
        targetCoordinate: CLLocationCoordinate2D?,
        targetAccuracy: CLLocationAccuracy?
    ) -> Bool {
        guard let distance = distance(to: targetCoordinate) else { return false }

        return distance <= arrivalRadius(targetAccuracy: targetAccuracy)
    }

    func isOutsideArrivalExitRadius(targetCoordinate: CLLocationCoordinate2D?) -> Bool {
        guard let distance = distance(to: targetCoordinate) else { return true }

        return distance > targetExitRadius
    }

    func directionInstruction(
        for relativeDegree: CGFloat,
        isFound: Bool,
        isTrackingParkingSpot: Bool
    ) -> String {
        guard !isFound else {
            return isTrackingParkingSpot ? "Parking spot ditemukan" : "Waypoint ditemukan"
        }

        let degree = normalizedDegrees(Double(relativeDegree))

        switch degree {
        case 0...20, 340...360:
            return "Lurus"
        case 20..<160:
            return "Belok kanan"
        case 160...200:
            return "Putar balik"
        case 200..<340:
            return "Belok kiri"
        default:
            return "Lurus"
        }
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
            locationManager.requestWhenInUseAuthorization()

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
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            statusText = "Location unavailable"
            completeCurrentLocationRequest(with: nil)
        }
    }
}

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
    private let locationRequestTimeout: TimeInterval = 2
    private let immediateAccuracyThreshold: CLLocationAccuracy = 10
    private let maximumUsableAccuracy: CLLocationAccuracy = 25
    private let recentLocationMaximumAge: TimeInterval = 5
    private let trackingSmoothingFactor = 0.45
    private var pendingLocationRequest: ((CLLocation?) -> Void)?
    private var pendingLocationTimeout: DispatchWorkItem?
    private var pendingBestLocation: CLLocation?
    private var latestRawLocation: CLLocation?

    override init() {
        authorizationStatus = locationManager.authorizationStatus

        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = 1
    }

    func requestAccessAndStartUpdating() {
        handleAuthorizationStatus(locationManager.authorizationStatus)
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    func requestCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            setPendingLocationRequest(completion)
            statusText = "Getting current location"
            locationManager.requestLocation()
        case .notDetermined:
            setPendingLocationRequest(completion)
            statusText = "Waiting for location permission"
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            statusText = "Location permission is off"
            completion(nil)
        @unknown default:
            statusText = "Location permission is unavailable"
            completion(nil)
        }
    }

    func relativeBearing(to targetCoordinate: CLLocationCoordinate2D?) -> CGFloat? {
        guard
            let currentCoordinate = currentLocation?.coordinate,
            let targetCoordinate
        else { return nil }

        let absoluteBearing = bearing(from: currentCoordinate, to: targetCoordinate)
        let headingDegrees = heading?.trueHeading ?? heading?.magneticHeading

        guard let headingDegrees, headingDegrees >= 0 else {
            return CGFloat(absoluteBearing)
        }

        return CGFloat(normalizedDegrees(absoluteBearing - headingDegrees))
    }

    func distanceText(to targetCoordinate: CLLocationCoordinate2D?) -> String {
        guard let distance = distance(to: targetCoordinate) else { return "-- m" }

        if distance >= 1_000 {
            return String(format: "%.1f km", distance / 1_000)
        }

        let roundedDistance = Int((distance / 5).rounded() * 5)

        return "\(max(roundedDistance, 0)) m"
    }

    func distance(to targetCoordinate: CLLocationCoordinate2D?) -> CLLocationDistance? {
        guard
            let currentLocation,
            let targetCoordinate
        else { return nil }

        let targetLocation = CLLocation(
            latitude: targetCoordinate.latitude,
            longitude: targetCoordinate.longitude
        )

        return currentLocation.distance(from: targetLocation)
    }

    func arrivalRadius(targetAccuracy: CLLocationAccuracy?) -> CLLocationDistance {
        let baseRadius: CLLocationDistance = 10
        let currentAccuracy = validAccuracy(currentLocation?.horizontalAccuracy)
        let targetAccuracy = validAccuracy(targetAccuracy)
        let accuracyPadding = min((currentAccuracy + targetAccuracy) * 0.25, 8)

        return baseRadius + accuracyPadding
    }

    func isInsideArrivalRadius(
        targetCoordinate: CLLocationCoordinate2D?,
        targetAccuracy: CLLocationAccuracy?
    ) -> Bool {
        guard let distance = distance(to: targetCoordinate) else { return false }

        return distance <= arrivalRadius(targetAccuracy: targetAccuracy)
    }
    
    func setBackgroundUpdates(_ enabled: Bool) {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            return
        }
        locationManager.allowsBackgroundLocationUpdates = enabled
        locationManager.pausesLocationUpdatesAutomatically = !enabled
    }

    private func setPendingLocationRequest(_ completion: @escaping (CLLocation?) -> Void) {
        pendingLocationTimeout?.cancel()
        pendingLocationRequest = completion
        pendingBestLocation = recentLocation(latestRawLocation) ?? recentLocation(currentLocation)
        isRequestingLocation = true

        let timeout = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self else { return }

                let location = self.pendingBestLocation
                    ?? self.recentLocation(self.latestRawLocation)
                    ?? self.recentLocation(self.currentLocation)
                self.statusText = location == nil ? "Location unavailable" : self.statusText(for: location)
                self.completePendingRequest(with: location)
            }
        }

        pendingLocationTimeout = timeout
        DispatchQueue.main.asyncAfter(
            deadline: .now() + locationRequestTimeout,
            execute: timeout
        )
    }

    private func completePendingRequest(with location: CLLocation?) {
        pendingLocationTimeout?.cancel()
        pendingLocationTimeout = nil

        let request = pendingLocationRequest
        pendingLocationRequest = nil
        pendingBestLocation = nil
        isRequestingLocation = false

        if let location {
            latestRawLocation = location
            updateTrackingLocation(with: location)
            statusText = statusText(for: location)
        }

        request?(location)
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        authorizationStatus = status

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            statusText = "Location data saves automatically"
            locationManager.startUpdatingLocation()

            if CLLocationManager.headingAvailable() {
                locationManager.startUpdatingHeading()
            }

            if pendingLocationRequest != nil {
                locationManager.requestLocation()
            }
        case .notDetermined:
            statusText = "Waiting for location permission"
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            statusText = "Location permission is off"
            completePendingRequest(with: nil)
        @unknown default:
            statusText = "Location permission is unavailable"
            completePendingRequest(with: nil)
        }
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

    private func handleUpdatedLocations(_ locations: [CLLocation]) {
        guard let bestLocation = bestLocation(in: locations) else { return }

        latestRawLocation = bestLocation
        updateTrackingLocation(with: bestLocation)
        statusText = statusText(for: bestLocation)

        guard pendingLocationRequest != nil else { return }

        pendingBestLocation = betterLocation(
            pendingBestLocation,
            than: bestLocation
        )

        if bestLocation.horizontalAccuracy <= immediateAccuracyThreshold {
            completePendingRequest(with: bestLocation)
        }
    }

    private func bestLocation(in locations: [CLLocation]) -> CLLocation? {
        locations
            .compactMap(recentLocation)
            .min { lhs, rhs in
                lhs.horizontalAccuracy < rhs.horizontalAccuracy
            }
    }

    private func betterLocation(_ currentBestLocation: CLLocation?, than candidateLocation: CLLocation) -> CLLocation {
        guard let currentBestLocation else { return candidateLocation }

        return candidateLocation.horizontalAccuracy < currentBestLocation.horizontalAccuracy
            ? candidateLocation
            : currentBestLocation
    }

    private func recentLocation(_ location: CLLocation?) -> CLLocation? {
        guard
            let location,
            location.horizontalAccuracy > 0,
            location.horizontalAccuracy <= maximumUsableAccuracy,
            Date().timeIntervalSince(location.timestamp) <= recentLocationMaximumAge
        else { return nil }

        return location
    }

    private func validAccuracy(_ accuracy: CLLocationAccuracy?) -> CLLocationAccuracy {
        guard let accuracy, accuracy > 0 else { return 0 }

        return accuracy
    }

    private func statusText(for location: CLLocation?) -> String {
        guard location != nil else { return "Location unavailable" }

        return "Location data saves automatically"
    }

    private func updateTrackingLocation(with rawLocation: CLLocation) {
        guard let existingLocation = currentLocation else {
            self.currentLocation = rawLocation

            return
        }

        let currentCoordinate = existingLocation.coordinate
        let rawCoordinate = rawLocation.coordinate
        let smoothedCoordinate = CLLocationCoordinate2D(
            latitude: currentCoordinate.latitude + (rawCoordinate.latitude - currentCoordinate.latitude) * trackingSmoothingFactor,
            longitude: currentCoordinate.longitude + (rawCoordinate.longitude - currentCoordinate.longitude) * trackingSmoothingFactor
        )

        currentLocation = CLLocation(
            coordinate: smoothedCoordinate,
            altitude: rawLocation.altitude,
            horizontalAccuracy: rawLocation.horizontalAccuracy,
            verticalAccuracy: rawLocation.verticalAccuracy,
            course: rawLocation.course,
            speed: rawLocation.speed,
            timestamp: rawLocation.timestamp
        )
    }
}

extension UserLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            handleAuthorizationStatus(manager.authorizationStatus)
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
            completePendingRequest(with: nil)
        }
    }
}

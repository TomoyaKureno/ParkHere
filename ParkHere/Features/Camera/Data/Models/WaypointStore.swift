//
//  WaypointStore.swift
//  ParkHere
//
//  Created by Kelly Angeline on 08/06/26.
//

import Combine
import CoreLocation
import Foundation
import UIKit

struct ParkingWaypoint: Identifiable, Equatable {
    let id: UUID
    let image: UIImage
    let latitude: Double?
    let longitude: Double?
    let horizontalAccuracy: Double?
    let capturedAt: Date
    let landmark: CurrentLandmark
    let altitude: AltitudeSample?

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation? {
        guard let coordinate else { return nil }

        return CLLocation(
            coordinate: coordinate,
            altitude: altitude?.absoluteAltitude ?? 0,
            horizontalAccuracy: horizontalAccuracy ?? -1,
            verticalAccuracy: -1,
            timestamp: capturedAt
        )
    }

    init(
        id: UUID = UUID(),
        image: UIImage,
        location: CLLocation?,
        landmark: CurrentLandmark = .unavailable,
        altitude: AltitudeSample? = nil,
        capturedAt: Date = .now
    ) {
        self.id = id
        self.image = image
        self.latitude = location?.coordinate.latitude
        self.longitude = location?.coordinate.longitude
        self.horizontalAccuracy = location?.horizontalAccuracy
        self.landmark = landmark
        self.capturedAt = capturedAt
        self.altitude = altitude
    }

    static func == (lhs: ParkingWaypoint, rhs: ParkingWaypoint) -> Bool {
        lhs.id == rhs.id
    }
}

enum LandmarkSelectionState {
    case available
    case current
    case passed
    case unavailable
}

final class WaypointStore: ObservableObject {
    @Published private(set) var capturedWaypoints: [ParkingWaypoint] = []
    @Published private(set) var retakeWaypointIDs: Set<UUID> = []
    @Published private(set) var trackingTargetIndex: Int?
    
    private var repository: ParkingRepository?

    var capturedImages: [UIImage] {
        capturedWaypoints.map(\.image)
    }

    var parkingCoordinate: CLLocationCoordinate2D? {
        capturedWaypoints.first?.coordinate
    }

    var hasSavedParkingSpot: Bool {
        !capturedWaypoints.isEmpty
    }

    var hasCompletedParkingCapture: Bool {
        hasSavedParkingSpot
    }

    var currentTrackingWaypoint: ParkingWaypoint? {
        guard
            let trackingTargetIndex,
            capturedWaypoints.indices.contains(trackingTargetIndex)
        else { return nil }

        return capturedWaypoints[trackingTargetIndex]
    }
    
    var currentTrackingAltitudeAnchor: AltitudeSample? {
        if isTrackingParkingSpot {
            return capturedWaypoints.first?.altitude
        }

        return currentTrackingWaypoint?.altitude
    }

    var currentTrackingCoordinate: CLLocationCoordinate2D? {
        if isTrackingParkingSpot {
            return parkingCoordinate
        }

        return currentTrackingWaypoint?.coordinate
    }

    var currentTrackingHorizontalAccuracy: Double? {
        if isTrackingParkingSpot {
            return capturedWaypoints.first?.horizontalAccuracy
        }

        return currentTrackingWaypoint?.horizontalAccuracy
    }

    var currentTrackingImage: UIImage? {
        return currentTrackingWaypoint?.image
    }

    var currentTrackingPhotoIndex: Int? {
        guard
            let trackingTargetIndex,
            capturedWaypoints.indices.contains(trackingTargetIndex)
        else { return nil }

        return trackingTargetIndex
    }

    var currentTrackingTitle: String {
        if isTrackingParkingSpot {
            return "Parking Spot"
        }

        guard let currentTrackingPhotoIndex else { return "Parking Spot" }

        return "Landmark \(currentTrackingPhotoIndex + 1)"
    }

    var currentTrackingProgressText: String {
        guard let currentTrackingPhotoIndex else {
            return "\(capturedWaypoints.count) points"
        }

        return "\(currentTrackingPhotoIndex + 1) of \(capturedWaypoints.count) points"
    }

    var remainingWaypointCount: Int {
        guard let trackingTargetIndex else { return 0 }

        return trackingTargetIndex + 1
    }

    var isTrackingParkingSpot: Bool {
        guard let trackingTargetIndex else { return true }

        return trackingTargetIndex == 0
    }
    
    func attach(repository: ParkingRepository) {
        self.repository = repository
    }
    
    func restoreFromPresistence() {
        capturedWaypoints = repository?.loadWaypoints() ?? []
    }

    @discardableResult
    func addWaypoint(
        _ image: UIImage,
        location: CLLocation?,
        landmark: CurrentLandmark = .unavailable,
        altitude: AltitudeSample? = nil
    ) -> UUID {
        let waypoint = ParkingWaypoint(
            image: image,
            location: location,
            landmark: landmark,
            altitude: altitude
        )
        capturedWaypoints.append(waypoint)
        persistWaypoints()

        return waypoint.id
    }

    @discardableResult
    func replaceWaypoint(
        at index: Int,
        image: UIImage,
        location: CLLocation?,
        landmark: CurrentLandmark = .unavailable,
        altitude: AltitudeSample? = nil
    ) -> UUID? {
        guard capturedWaypoints.indices.contains(index) else { return nil }

        let previousWaypoint = capturedWaypoints[index]
        var updatedWaypoints = capturedWaypoints
        updatedWaypoints[index] = ParkingWaypoint(
            image: image,
            location: location,
            landmark: landmark,
            altitude: altitude
        )
        capturedWaypoints = updatedWaypoints

        var updatedRetakeIDs = retakeWaypointIDs
        updatedRetakeIDs.remove(previousWaypoint.id)
        retakeWaypointIDs = updatedRetakeIDs
        persistWaypoints()

        return updatedWaypoints[index].id
    }

    func updateWaypointLandmark(id: UUID, landmark: CurrentLandmark) {
        guard let index = capturedWaypoints.firstIndex(where: { $0.id == id }) else { return }

        let waypoint = capturedWaypoints[index]
        var updatedWaypoints = capturedWaypoints
        updatedWaypoints[index] = ParkingWaypoint(
            id: waypoint.id,
            image: waypoint.image,
            location: waypoint.location,
            landmark: landmark,
            altitude: waypoint.altitude,
            capturedAt: waypoint.capturedAt
        )
        capturedWaypoints = updatedWaypoints
        persistWaypoints()
    }

    func markWaypointForRetake(at index: Int) {
        guard capturedWaypoints.indices.contains(index) else { return }

        var updatedRetakeIDs = retakeWaypointIDs
        updatedRetakeIDs.insert(capturedWaypoints[index].id)
        retakeWaypointIDs = updatedRetakeIDs
    }

    func isWaypointRetakeNeeded(at index: Int) -> Bool {
        guard capturedWaypoints.indices.contains(index) else { return false }

        return retakeWaypointIDs.contains(capturedWaypoints[index].id)
    }

    func removeRetakeWaypoints() {
        guard !retakeWaypointIDs.isEmpty else { return }

        let oldWaypoints = capturedWaypoints
        let removedIDs = retakeWaypointIDs
        let updatedWaypoints = oldWaypoints.filter { waypoint in
            !removedIDs.contains(waypoint.id)
        }

        if
            let trackingTargetIndex,
            oldWaypoints.indices.contains(trackingTargetIndex)
        {
            let targetID = oldWaypoints[trackingTargetIndex].id
            self.trackingTargetIndex = updatedWaypoints.firstIndex { waypoint in
                waypoint.id == targetID
            }
        } else if trackingTargetIndex != nil {
            trackingTargetIndex = nil
        }

        capturedWaypoints = updatedWaypoints
        retakeWaypointIDs = []
        persistWaypoints()
    }

    func removeWaypoint(at index: Int) {
        guard capturedWaypoints.indices.contains(index) else { return }

        var updatedRetakeIDs = retakeWaypointIDs
        updatedRetakeIDs.remove(capturedWaypoints[index].id)
        retakeWaypointIDs = updatedRetakeIDs

        var updatedWaypoints = capturedWaypoints
        updatedWaypoints.remove(at: index)
        capturedWaypoints = updatedWaypoints
        persistWaypoints()
    }

    func clearWaypoints() {
        capturedWaypoints.removeAll()
        retakeWaypointIDs.removeAll()
        trackingTargetIndex = nil
        repository?.clearWaypoints()
    }

    func prepareTracking() {
        trackingTargetIndex = capturedWaypoints.indices.last
    }

    func prepareTracking(from location: CLLocation?) {
        guard let location else {
            prepareTracking()
            return
        }

        trackingTargetIndex = nearestTrackingTargetIndex(from: location)
            ?? capturedWaypoints.indices.last
    }

    func advanceToNextTrackingTarget() -> Bool {
        guard let trackingTargetIndex else {
            return false
        }

        guard trackingTargetIndex > 0 else {
            self.trackingTargetIndex = nil

            return false
        }

        self.trackingTargetIndex = trackingTargetIndex - 1

        return true
    }

    func skipToParkingSpot() {
        trackingTargetIndex = capturedWaypoints.isEmpty ? nil : 0
    }

    func setTrackingTargetIndex(_ index: Int) {
        guard capturedWaypoints.indices.contains(index) else { return }

        trackingTargetIndex = index
    }

    func landmarkSelectionState(for index: Int) -> LandmarkSelectionState {
        guard capturedWaypoints.indices.contains(index) else {
            return .unavailable
        }

        guard let trackingTargetIndex else {
            return .unavailable
        }

        if index == trackingTargetIndex {
            return .current
        }

        return index < trackingTargetIndex ? .available : .passed
    }

    func useLandmarkInstead(at index: Int) {
        guard landmarkSelectionState(for: index) == .available else { return }

        trackingTargetIndex = index
    }

    private func nearestTrackingTargetIndex(from location: CLLocation) -> Int? {
        capturedWaypoints.indices
            .compactMap { index -> (index: Int, distance: CLLocationDistance)? in
                guard let coordinate = trackingCoordinate(for: index) else { return nil }

                let targetLocation = CLLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )

                return (index, location.distance(from: targetLocation))
            }
            .min { lhs, rhs in
                lhs.distance < rhs.distance
            }?
            .index
    }

    private func trackingCoordinate(for index: Int) -> CLLocationCoordinate2D? {
        guard capturedWaypoints.indices.contains(index) else { return nil }

        return capturedWaypoints[index].coordinate
    }

    func clearParkingSpot() {
        clearWaypoints()
    }

    private func persistWaypoints() {
        repository?.saveWaypoints(capturedWaypoints)
    }
}

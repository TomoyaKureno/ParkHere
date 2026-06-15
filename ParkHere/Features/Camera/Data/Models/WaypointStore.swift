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
    let id = UUID()
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

    init(image: UIImage, location: CLLocation?, landmark: CurrentLandmark = .unavailable, altitude: AltitudeSample? = nil) {
        self.image = image
        self.latitude = location?.coordinate.latitude
        self.longitude = location?.coordinate.longitude
        self.horizontalAccuracy = location?.horizontalAccuracy
        self.landmark = landmark
        self.capturedAt = .now
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
    @Published private(set) var parkingLatitude: Double?
    @Published private(set) var parkingLongitude: Double?
    @Published private(set) var parkingHorizontalAccuracy: Double?
    @Published private(set) var trackingTargetIndex: Int?
    @Published private(set) var parkingAltitudeAnchor: AltitudeSample?
    
    private var repository: ParkingRepository?

    var capturedImages: [UIImage] {
        capturedWaypoints.map(\.image)
    }

    var parkingCoordinate: CLLocationCoordinate2D? {
        guard let parkingLatitude, let parkingLongitude else { return nil }

        return CLLocationCoordinate2D(
            latitude: parkingLatitude,
            longitude: parkingLongitude
        )
    }

    var hasSavedParkingSpot: Bool {
        parkingCoordinate != nil
    }

    var hasCompletedParkingCapture: Bool {
        hasSavedParkingSpot && !capturedWaypoints.isEmpty
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
            return parkingAltitudeAnchor ?? capturedWaypoints.first?.altitude
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
            return parkingHorizontalAccuracy
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
        guard let record = repository?.loadActive() else { return }
        parkingLatitude = record.latitude
        parkingLongitude = record.longitude
        parkingHorizontalAccuracy = record.horizontalAccuracy
        
        if record.absoluteAltitude != nil || record.pressureKPa != nil {
            parkingAltitudeAnchor = AltitudeSample(
                absoluteAltitude: record.absoluteAltitude,
                pressureKPa: record.pressureKPa,
                relativeAltitude: record.relativeAltitude,
                capturedAt: record.createdAt
            )
        }
    }

    func saveParkingLocation(_ location: CLLocation?, altitude: AltitudeSample? = nil) {
        parkingLatitude = location?.coordinate.latitude
        parkingLongitude = location?.coordinate.longitude
        parkingHorizontalAccuracy = location?.horizontalAccuracy
        parkingAltitudeAnchor = altitude
        
        repository?.save(
            coordinate: location?.coordinate,
            horizontalAccuracy: location?.horizontalAccuracy,
            altitude: altitude
        )
    }

    func addWaypoint(_ image: UIImage, location: CLLocation?, landmark: CurrentLandmark = .unavailable, altitude: AltitudeSample? = nil) {
        capturedWaypoints.append(ParkingWaypoint(image: image, location: location, landmark: landmark, altitude: altitude))
    }

    func replaceWaypoint(at index: Int, image: UIImage, location: CLLocation?, landmark: CurrentLandmark = .unavailable, altitude: AltitudeSample? = nil) {
        guard capturedWaypoints.indices.contains(index) else { return }

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
    }

    func removeWaypoint(at index: Int) {
        guard capturedWaypoints.indices.contains(index) else { return }

        var updatedRetakeIDs = retakeWaypointIDs
        updatedRetakeIDs.remove(capturedWaypoints[index].id)
        retakeWaypointIDs = updatedRetakeIDs

        var updatedWaypoints = capturedWaypoints
        updatedWaypoints.remove(at: index)
        capturedWaypoints = updatedWaypoints
    }

    func clearWaypoints() {
        capturedWaypoints.removeAll()
        retakeWaypointIDs.removeAll()
        trackingTargetIndex = nil
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

        if index == capturedWaypoints.indices.first {
            return parkingCoordinate ?? capturedWaypoints[index].coordinate
        }

        return capturedWaypoints[index].coordinate
    }

    func clearParkingSpot() {
        parkingLatitude = nil
        parkingLongitude = nil
        parkingHorizontalAccuracy = nil
        parkingAltitudeAnchor = nil
        repository?.clear()
        clearWaypoints()
    }
}

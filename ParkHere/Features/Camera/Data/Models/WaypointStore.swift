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

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(image: UIImage, location: CLLocation?) {
        self.image = image
        latitude = location?.coordinate.latitude
        longitude = location?.coordinate.longitude
        horizontalAccuracy = location?.horizontalAccuracy
    }

    static func == (lhs: ParkingWaypoint, rhs: ParkingWaypoint) -> Bool {
        lhs.id == rhs.id
    }
}

final class WaypointStore: ObservableObject {
    @Published private(set) var capturedWaypoints: [ParkingWaypoint] = []
    @Published private(set) var parkingLatitude: Double?
    @Published private(set) var parkingLongitude: Double?
    @Published private(set) var parkingHorizontalAccuracy: Double?
    @Published private(set) var trackingTargetIndex: Int?

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

    var currentTrackingWaypoint: ParkingWaypoint? {
        guard
            let trackingTargetIndex,
            capturedWaypoints.indices.contains(trackingTargetIndex)
        else { return nil }

        return capturedWaypoints[trackingTargetIndex]
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

    var remainingWaypointCount: Int {
        guard let trackingTargetIndex else { return 0 }

        return trackingTargetIndex + 1
    }

    var isTrackingParkingSpot: Bool {
        guard let trackingTargetIndex else { return true }

        return trackingTargetIndex == 0
    }

    func saveParkingLocation(_ location: CLLocation?) {
        parkingLatitude = location?.coordinate.latitude
        parkingLongitude = location?.coordinate.longitude
        parkingHorizontalAccuracy = location?.horizontalAccuracy
    }

    func addWaypoint(_ image: UIImage, location: CLLocation?) {
        capturedWaypoints.append(ParkingWaypoint(image: image, location: location))
    }

    func removeWaypoint(at index: Int) {
        guard capturedWaypoints.indices.contains(index) else { return }

        capturedWaypoints.remove(at: index)
    }

    func clearWaypoints() {
        capturedWaypoints.removeAll()
        trackingTargetIndex = nil
    }

    func prepareTracking() {
        trackingTargetIndex = capturedWaypoints.indices.last
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

    func clearParkingSpot() {
        parkingLatitude = nil
        parkingLongitude = nil
        parkingHorizontalAccuracy = nil
        clearWaypoints()
    }
}

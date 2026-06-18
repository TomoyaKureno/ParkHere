//
//  LandmarkStore.swift
//  ParkHere
//
//  Created by Kelly Angeline on 08/06/26.
//

import Combine
import CoreLocation
import Foundation
import UIKit

struct ParkingLandmark: Identifiable, Equatable {
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

    static func == (lhs: ParkingLandmark, rhs: ParkingLandmark) -> Bool {
        lhs.id == rhs.id
    }
}

enum LandmarkSelectionState {
    case available
    case current
    case passed
    case unavailable
}

@MainActor
final class LandmarkStore: ObservableObject {
    @Published private(set) var capturedLandmarks: [ParkingLandmark] = []
    @Published private(set) var retakeLandmarkIDs: Set<UUID> = []
    @Published private(set) var trackingTargetIndex: Int?
    
    private var repository: ParkingRepository?

    var hasCompletedParkingCapture: Bool {
        !capturedLandmarks.isEmpty
    }

    var currentTrackingLandmark: ParkingLandmark? {
        guard
            let trackingTargetIndex,
            capturedLandmarks.indices.contains(trackingTargetIndex)
        else { return nil }

        return capturedLandmarks[trackingTargetIndex]
    }
    
    var currentTrackingAltitudeAnchor: AltitudeSample? {
        if isTrackingParkingSpot {
            return capturedLandmarks.first?.altitude
        }

        return currentTrackingLandmark?.altitude
    }

    var currentTrackingCoordinate: CLLocationCoordinate2D? {
        if isTrackingParkingSpot {
            return capturedLandmarks.first?.coordinate
        }

        return currentTrackingLandmark?.coordinate
    }

    var currentTrackingHorizontalAccuracy: Double? {
        if isTrackingParkingSpot {
            return capturedLandmarks.first?.horizontalAccuracy
        }

        return currentTrackingLandmark?.horizontalAccuracy
    }

    var currentTrackingImage: UIImage? {
        return currentTrackingLandmark?.image
    }

    var currentTrackingPhotoIndex: Int? {
        guard
            let trackingTargetIndex,
            capturedLandmarks.indices.contains(trackingTargetIndex)
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
            return "\(capturedLandmarks.count) points"
        }

        return "\(currentTrackingPhotoIndex + 1) of \(capturedLandmarks.count) points"
    }

    var isTrackingParkingSpot: Bool {
        guard let trackingTargetIndex else { return true }

        return trackingTargetIndex == 0
    }
    
    func attach(repository: ParkingRepository) {
        self.repository = repository
    }
    
    func restoreFromPersistence() {
        capturedLandmarks = repository?.loadLandmarks() ?? []
    }

    @discardableResult
    func addLandmark(
        _ image: UIImage,
        location: CLLocation?,
        landmark: CurrentLandmark = .unavailable,
        altitude: AltitudeSample? = nil
    ) -> UUID {
        let capturedLandmark = ParkingLandmark(
            image: image,
            location: location,
            landmark: landmark,
            altitude: altitude
        )
        capturedLandmarks.append(capturedLandmark)
        persistLandmarks()

        return capturedLandmark.id
    }

    @discardableResult
    func replaceLandmark(
        at index: Int,
        image: UIImage,
        location: CLLocation?,
        landmark: CurrentLandmark = .unavailable,
        altitude: AltitudeSample? = nil
    ) -> UUID? {
        guard capturedLandmarks.indices.contains(index) else { return nil }

        let previousLandmark = capturedLandmarks[index]
        var updatedLandmarks = capturedLandmarks
        updatedLandmarks[index] = ParkingLandmark(
            image: image,
            location: location,
            landmark: landmark,
            altitude: altitude
        )
        capturedLandmarks = updatedLandmarks

        var updatedRetakeIDs = retakeLandmarkIDs
        updatedRetakeIDs.remove(previousLandmark.id)
        retakeLandmarkIDs = updatedRetakeIDs
        persistLandmarks()

        return updatedLandmarks[index].id
    }

    func updateCapturedLandmark(id: UUID, landmark: CurrentLandmark) {
        guard let index = capturedLandmarks.firstIndex(where: { $0.id == id }) else { return }

        let capturedLandmark = capturedLandmarks[index]
        var updatedLandmarks = capturedLandmarks
        updatedLandmarks[index] = ParkingLandmark(
            id: capturedLandmark.id,
            image: capturedLandmark.image,
            location: capturedLandmark.location,
            landmark: landmark,
            altitude: capturedLandmark.altitude,
            capturedAt: capturedLandmark.capturedAt
        )
        capturedLandmarks = updatedLandmarks
        persistLandmarks()
    }

    func markLandmarkForRetake(at index: Int) {
        guard capturedLandmarks.indices.contains(index) else { return }

        var updatedRetakeIDs = retakeLandmarkIDs
        updatedRetakeIDs.insert(capturedLandmarks[index].id)
        retakeLandmarkIDs = updatedRetakeIDs
    }

    func isLandmarkRetakeNeeded(at index: Int) -> Bool {
        guard capturedLandmarks.indices.contains(index) else { return false }

        return retakeLandmarkIDs.contains(capturedLandmarks[index].id)
    }

    func removeRetakeLandmarks() {
        guard !retakeLandmarkIDs.isEmpty else { return }

        let oldLandmarks = capturedLandmarks
        let removedIDs = retakeLandmarkIDs
        let updatedLandmarks = oldLandmarks.filter { landmark in
            !removedIDs.contains(landmark.id)
        }

        if
            let trackingTargetIndex,
            oldLandmarks.indices.contains(trackingTargetIndex)
        {
            let targetID = oldLandmarks[trackingTargetIndex].id
            self.trackingTargetIndex = updatedLandmarks.firstIndex { landmark in
                landmark.id == targetID
            }
        } else if trackingTargetIndex != nil {
            trackingTargetIndex = nil
        }

        capturedLandmarks = updatedLandmarks
        retakeLandmarkIDs = []
        persistLandmarks()
    }

    func clearLandmarks() {
        capturedLandmarks.removeAll()
        retakeLandmarkIDs.removeAll()
        trackingTargetIndex = nil
        repository?.clearLandmarks()
    }

    func prepareTracking() {
        trackingTargetIndex = capturedLandmarks.indices.last
    }

    func prepareTracking(from location: CLLocation?) {
        guard let location else {
            prepareTracking()
            return
        }

        trackingTargetIndex = nearestTrackingTargetIndex(from: location)
            ?? capturedLandmarks.indices.last
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
        trackingTargetIndex = capturedLandmarks.isEmpty ? nil : 0
    }

    func landmarkSelectionState(for index: Int) -> LandmarkSelectionState {
        guard capturedLandmarks.indices.contains(index) else {
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

    func nearestRerouteCandidate(
        from location: CLLocation?,
        minimumSavedDistance: CLLocationDistance,
        isSameFloor: (ParkingLandmark) -> Bool
    ) -> LandmarkRerouteCandidate? {
        guard
            let location,
            let trackingTargetIndex,
            trackingTargetIndex > 0,
            capturedLandmarks.indices.contains(trackingTargetIndex),
            let currentTargetLocation = trackingLocation(for: trackingTargetIndex)
        else { return nil }

        let currentTargetDistance = location.distance(from: currentTargetLocation)

        return capturedLandmarks.indices
            .filter { $0 < trackingTargetIndex }
            .compactMap { index -> LandmarkRerouteCandidate? in
                let landmark = capturedLandmarks[index]

                guard
                    isSameFloor(landmark),
                    let candidateLocation = trackingLocation(for: index)
                else { return nil }

                let candidateDistance = location.distance(from: candidateLocation)
                let savedDistance = currentTargetDistance - candidateDistance

                guard savedDistance >= minimumSavedDistance else { return nil }

                return LandmarkRerouteCandidate(
                    index: index,
                    image: landmark.image,
                    title: trackingTitle(for: index),
                    subtitle: landmark.landmark.title,
                    candidateDistance: candidateDistance,
                    currentTargetDistance: currentTargetDistance,
                    savedDistance: savedDistance
                )
            }
            .min { lhs, rhs in
                lhs.candidateDistance < rhs.candidateDistance
            }
    }

    func rerouteTracking(to index: Int) {
        guard
            let trackingTargetIndex,
            capturedLandmarks.indices.contains(index),
            index < trackingTargetIndex
        else { return }

        self.trackingTargetIndex = index
    }

    private func nearestTrackingTargetIndex(from location: CLLocation) -> Int? {
        capturedLandmarks.indices
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

    private func trackingTitle(for index: Int) -> String {
        guard capturedLandmarks.indices.contains(index) else { return "Landmark" }

        if index == capturedLandmarks.indices.first {
            return "Parking Spot"
        }

        if index == capturedLandmarks.indices.last {
            return "Final Spot"
        }

        return "Landmark \(index)"
    }

    private func trackingLocation(for index: Int) -> CLLocation? {
        guard let coordinate = trackingCoordinate(for: index) else { return nil }

        return CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    private func trackingCoordinate(for index: Int) -> CLLocationCoordinate2D? {
        guard capturedLandmarks.indices.contains(index) else { return nil }

        return capturedLandmarks[index].coordinate
    }

    func clearParkingSpot() {
        clearLandmarks()
    }

    private func persistLandmarks() {
        repository?.saveLandmarks(capturedLandmarks)
    }
}

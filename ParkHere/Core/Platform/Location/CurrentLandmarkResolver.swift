//
//  CurrentLandmarkResolver.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 14/06/26.
//

import CoreLocation
import Foundation
import MapKit

struct CurrentLandmarkResolver {
    private let preciseLandmarkSearchRadius: CLLocationDistance = 120
    private let fallbackLandmarkSearchRadius: CLLocationDistance = 250

    func landmark(near location: CLLocation?) async -> CurrentLandmark {
        guard let location else { return .unavailable }

        if let pointOfInterestLandmark = await pointOfInterestLandmark(near: location) {
            return pointOfInterestLandmark
        }

        return await reverseGeocodedLandmark(near: location) ?? .unavailable
    }

    private func pointOfInterestLandmark(near location: CLLocation) async -> CurrentLandmark? {
        let request = MKLocalPointsOfInterestRequest(
            center: location.coordinate,
            radius: preciseLandmarkSearchRadius
        )
        request.pointOfInterestFilter = .includingAll

        let response = try? await MKLocalSearch(request: request).start()
        guard let bestItem = response?.mapItems.min(by: {
            mapItemScore($0, from: location) < mapItemScore($1, from: location)
        }) else {
            return await fallbackPointOfInterestLandmark(near: location)
        }

        return CurrentLandmark(
            title: preciseTitle(from: bestItem),
            subtitle: formattedAddress(from: bestItem)
        )
    }

    private func fallbackPointOfInterestLandmark(near location: CLLocation) async -> CurrentLandmark? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "point of interest"
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = .includingAll
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: fallbackLandmarkSearchRadius,
            longitudinalMeters: fallbackLandmarkSearchRadius
        )

        let response = try? await MKLocalSearch(request: request).start()
        guard let bestItem = response?.mapItems.min(by: {
            mapItemScore($0, from: location) < mapItemScore($1, from: location)
        }) else { return nil }

        return CurrentLandmark(
            title: preciseTitle(from: bestItem),
            subtitle: formattedAddress(from: bestItem)
        )
    }

    private func reverseGeocodedLandmark(near location: CLLocation) async -> CurrentLandmark? {
        guard
            let request = MKReverseGeocodingRequest(location: location),
            let mapItem = try? await request.mapItems.first
        else {
            return nil
        }

        return CurrentLandmark(
            title: preciseTitle(from: mapItem),
            subtitle: formattedAddress(from: mapItem)
        )
    }

    private func mapItemDistance(_ mapItem: MKMapItem, from location: CLLocation) -> CLLocationDistance {
        mapItem.location.distance(from: location)
    }

    private func mapItemScore(_ mapItem: MKMapItem, from location: CLLocation) -> CLLocationDistance {
        let distanceScore = mapItemDistance(mapItem, from: location)
        let broadCategoryPenalty: CLLocationDistance = isBroadCategory(mapItem.pointOfInterestCategory) ? 80 : 0
        let namedPlaceBonus: CLLocationDistance = hasSpecificName(mapItem) ? -25 : 0

        return distanceScore + broadCategoryPenalty + namedPlaceBonus
    }

    private func isBroadCategory(_ category: MKPointOfInterestCategory?) -> Bool {
        guard let category else { return false }

        let rawValue = category.rawValue.lowercased()
        let broadKeywords = [
            "airport",
            "amusement",
            "beach",
            "campground",
            "marina",
            "nationalpark",
            "park",
            "parking",
            "publictransport",
            "stadium",
            "university"
        ]

        return broadKeywords.contains { rawValue.contains($0) }
    }

    private func hasSpecificName(_ mapItem: MKMapItem) -> Bool {
        guard let name = mapItem.name?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }

        return !name.isEmpty && name != formattedAddress(from: mapItem)
    }

    private func preciseTitle(from mapItem: MKMapItem) -> String {
        if let name = mapItem.name, !name.isEmpty {
            return name
        }

        return mapItem.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true)
            ?? mapItem.addressRepresentations?.cityWithContext(.short)
            ?? "Current location"
    }

    private func formattedAddress(from mapItem: MKMapItem) -> String {
        mapItem.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true)
            ?? mapItem.addressRepresentations?.cityWithContext(.short)
            ?? "Nearby your current location"
    }
}

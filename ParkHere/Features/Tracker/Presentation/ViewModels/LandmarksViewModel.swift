//
//  LandmarksViewModel.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 18/06/26.
//

import Combine
import SwiftUI

@MainActor
final class LandmarksViewModel: ObservableObject {
    @Published var isDetailPresented = false
    @Published var selectedDetailLandmarkIndex: Int?
    @Published var deleteRequest: LandmarkDeleteRequest?

    private let store: LandmarkStore
    private let locationManager: UserLocationManager
    private let altimeterManager: AltimeterManager
    private let floorEstimator = FloorEstimator()
    private let isGallery: Bool

    init(
        store: LandmarkStore,
        locationManager: UserLocationManager,
        altimeterManager: AltimeterManager,
        isGallery: Bool
    ) {
        self.store = store
        self.locationManager = locationManager
        self.altimeterManager = altimeterManager
        self.isGallery = isGallery
    }

    var orderedLandmarkIndices: [Int] {
        Array(store.capturedLandmarks.indices.reversed())
    }

    var photoCountText: String {
        "\(store.capturedLandmarks.count) Photos"
    }

    var detailLandmarkIndices: [Int] {
        orderedLandmarkIndices
    }

    var isDeleteAlertPresented: Bool {
        deleteRequest != nil
    }

    func setDeleteAlertPresented(_ isPresented: Bool) {
        if !isPresented {
            deleteRequest = nil
        }
    }

    func requestDelete(at landmarkIndex: Int) {
        deleteRequest = LandmarkDeleteRequest(
            landmarkIndex: landmarkIndex,
            title: "Delete \(landmarkLabel(for: landmarkIndex).text)"
        )
    }

    func showDetail(for landmarkIndex: Int, visualIndex: Int) {
        guard store.capturedLandmarks.indices.contains(landmarkIndex) else { return }

        selectedDetailLandmarkIndex = landmarkIndex
        isDetailPresented = true
    }

    func detail(for landmarkIndex: Int) -> LandmarkDetail? {
        guard let visualIndex = orderedLandmarkIndices.firstIndex(of: landmarkIndex) else { return nil }

        return detail(for: landmarkIndex, visualIndex: visualIndex)
    }

    func visualIndex(for landmarkIndex: Int) -> Int? {
        orderedLandmarkIndices.firstIndex(of: landmarkIndex)
    }

    func selectDetail(at landmarkIndex: Int) {
        guard store.capturedLandmarks.indices.contains(landmarkIndex) else { return }

        selectedDetailLandmarkIndex = landmarkIndex
    }

    func clearDetailSelection() {
        isDetailPresented = false
        selectedDetailLandmarkIndex = nil
    }

    func landmarkLabel(for landmarkIndex: Int) -> LandmarkBadgeInfo {
        guard
            let firstIndex = store.capturedLandmarks.indices.first
        else {
            return LandmarkBadgeInfo(text: "Landmark", color: .blue)
        }

        if landmarkIndex == firstIndex {
            return LandmarkBadgeInfo(text: "Parking Spot", color: .blue)
        }

        return LandmarkBadgeInfo(text: "Landmark \(landmarkIndex)", color: .blue)
    }

    func distanceText(for landmarkIndex: Int) -> String {
        guard store.capturedLandmarks.indices.contains(landmarkIndex) else { return "-- m" }

        return locationManager.distanceText(to: store.capturedLandmarks[landmarkIndex].coordinate)
    }

    func floorText(for landmarkIndex: Int) -> String {
        guard
            store.capturedLandmarks.indices.contains(landmarkIndex),
            let delta = floorDeltaMeters(to: store.capturedLandmarks[landmarkIndex].altitude)
        else { return "--" }

        let floors = floorEstimator.floors(deltaMeters: delta, previousFloors: 0)
        return floorEstimator.shortLabel(floors)
    }

    func confirmDelete() {
        guard let deleteRequest else { return }

        store.deleteLandmark(at: deleteRequest.landmarkIndex)
        self.deleteRequest = nil
    }

    func handleBack(onTapBack: () -> Void) {
        onTapBack()
    }

    private func detail(for landmarkIndex: Int, visualIndex: Int) -> LandmarkDetail? {
        guard store.capturedLandmarks.indices.contains(landmarkIndex) else { return nil }

        let landmark = store.capturedLandmarks[landmarkIndex]
        return LandmarkDetail(
            landmarkIndex: landmarkIndex,
            image: landmark.image,
            title: landmarkLabel(for: landmarkIndex).text,
            subtitle: landmark.landmark.title,
            progressText: "\(visualIndex + 1) of \(orderedLandmarkIndices.count) points",
            selectionState: store.landmarkSelectionState(for: landmarkIndex)
        )
    }

    private func floorDeltaMeters(to anchor: AltitudeSample?) -> Double? {
        guard let anchor else { return nil }

        let accuracyThreshold = floorEstimator.floorHeight / 2

        if let currentAlt = altimeterManager.absoluteAltitude,
           let currentAcc = altimeterManager.absoluteAltitudeAccuracy,
           currentAcc < accuracyThreshold,
           let anchorAlt = anchor.absoluteAltitude,
           let anchorAcc = anchor.absoluteAltitudeAccuracy,
           anchorAcc < accuracyThreshold
        {
            return anchorAlt - currentAlt
        }

        if anchor.sessionID == altimeterManager.sessionID,
           let currentRel = altimeterManager.relativeAltitude,
           let anchorRel = anchor.relativeAltitude
        {
            return anchorRel - currentRel
        }

        if let anchorPressure = anchor.pressureKPa,
           let sessionStartPressure = altimeterManager.sessionStartPressure,
           let currentRelative = altimeterManager.relativeAltitude
        {
            let sessionOffset = (sessionStartPressure - anchorPressure) * 83.0
            return sessionOffset - currentRelative
        }

        return nil
    }
}

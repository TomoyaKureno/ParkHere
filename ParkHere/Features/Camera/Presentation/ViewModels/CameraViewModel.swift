//
//  CameraViewModel.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 18/06/26.
//

import Combine
import CoreLocation
import Foundation
import UIKit

@MainActor
final class CameraViewModel: ObservableObject {
    @Published var showDoneAlert = false
    @Published var didFinishCapture = false
    @Published var isSavingPreviewLandmark = false
    @Published var isOpeningLandmarkGallery = false
    @Published var showOverlay = false
    @Published var showDiscardAlert = false
    @Published var showFirstPhotoAlert = false

    private let store: LandmarkStore
    private let locationManager: UserLocationManager
    private let altimeterManager: AltimeterManager
    private let retakeIndex: Int?
    private let landmarkResolver = CurrentLandmarkResolver()

    init(
        store: LandmarkStore,
        locationManager: UserLocationManager,
        altimeterManager: AltimeterManager,
        retakeIndex: Int?
    ) {
        self.store = store
        self.locationManager = locationManager
        self.altimeterManager = altimeterManager
        self.retakeIndex = retakeIndex
    }

    var cameraTitle: String {
        if retakeIndex != nil {
            return "Retake Landmark"
        }

        return store.capturedLandmarks.isEmpty
            ? "Capture Parking Spot"
            : "Capture Landmark \(store.capturedLandmarks.count)"
    }

    var cameraSubtitle: String {
        if retakeIndex != nil {
            return "Retake this photo to keep your route landmarks complete."
        }

        return store.capturedLandmarks.isEmpty
            ? "Start by capturing photo around your parking spot (car or unique object)"
            : "Capture multiple landmarks to help guide you back to your parking spot"
    }

    var cameraLocationStatusText: String {
        if locationManager.currentCaptureLocation != nil {
            return locationManager.statusText
        }

        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            return locationManager.statusText
        default:
            return "Getting current location"
        }
    }

    var isThumbnailDisabled: Bool {
        store.capturedLandmarks.isEmpty || retakeIndex != nil
    }

    var isDoneDisabled: Bool {
        store.capturedLandmarks.isEmpty
            || !store.retakeLandmarkIDs.isEmpty
            || retakeIndex != nil
    }

    var currentCaptureLocation: CLLocation? {
        locationManager.currentCaptureLocation
    }

    func onAppear(cameraManager: CameraManager) {
        isOpeningLandmarkGallery = false
        cameraManager.startSession()
        locationManager.requestAccessAndStartUpdating()
        altimeterManager.start()
    }

    func onDisappear(cameraManager: CameraManager) {
        cameraManager.stopSession()
        altimeterManager.stop()

        if !didFinishCapture && retakeIndex == nil && !isOpeningLandmarkGallery {
            store.clearParkingSpot()
        }
    }

    func onScenePhaseActive(cameraManager: CameraManager) {
        cameraManager.startSession()
    }

    func handleBack(onPop: () -> Void) {
        if store.capturedLandmarks.isEmpty {
            cancelCapture(onPop: onPop)
        } else {
            showDiscardAlert = true
        }
    }

    func requestDoneAlert() {
        showDoneAlert = true
    }

    func dismissFirstPhotoAlert() {
        showFirstPhotoAlert = false
    }

    func capturePhoto(
        using cameraManager: CameraManager,
        shouldShowFirstPhotoAlert: Bool,
        onRetakeFinished: @escaping () -> Void
    ) {
        guard let captureLocation = currentCaptureLocation else {
            locationManager.requestAccessAndStartUpdating()
            return
        }

        cameraManager.takePhoto(location: captureLocation) { [weak self] image, location in
            self?.saveCapturedLandmark(
                image: image,
                location: location,
                shouldShowFirstPhotoAlert: shouldShowFirstPhotoAlert,
                onRetakeFinished: onRetakeFinished
            )
        }
    }

    func cancelCapture(onPop: () -> Void) {
        if retakeIndex == nil {
            store.clearParkingSpot()
        }

        onPop()
    }

    func finishCapture(onDone: () -> Void) {
        didFinishCapture = true
        onDone()
    }

    func openLandmarkGallery(onTapLandmarks: () -> Void) {
        guard !store.capturedLandmarks.isEmpty else { return }

        showDoneAlert = false
        isOpeningLandmarkGallery = true
        onTapLandmarks()
    }

    private func saveCapturedLandmark(
        image: UIImage,
        location: CLLocation?,
        shouldShowFirstPhotoAlert: Bool,
        onRetakeFinished: @escaping () -> Void
    ) {
        guard !isSavingPreviewLandmark else { return }

        isSavingPreviewLandmark = true
        let altitude = altimeterManager.currentSample()
        let landmarkID: UUID?

        if let retakeIndex {
            landmarkID = store.replaceLandmark(
                at: retakeIndex,
                image: image,
                location: location,
                landmark: .loading,
                altitude: altitude
            )
            isSavingPreviewLandmark = false
            finishCapture(onDone: onRetakeFinished)
        } else {
            landmarkID = store.addLandmark(
                image,
                location: location,
                landmark: .loading,
                altitude: altitude
            )
            isSavingPreviewLandmark = false

            if shouldShowFirstPhotoAlert {
                showFirstPhotoAlert = true
            }
        }

        guard let landmarkID else { return }

        let resolver = landmarkResolver
        let landmarkStore = store

        Task { @MainActor in
            let landmark = await resolver.landmark(near: location)
            landmarkStore.updateCapturedLandmark(id: landmarkID, landmark: landmark)
        }
    }
}

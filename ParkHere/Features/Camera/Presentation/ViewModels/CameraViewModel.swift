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
    @Published var showLandmarksOverlay = false

    private let store: LandmarkStore
    private let locationManager: UserLocationManager
    private let altimeterManager: AltimeterManager
    private let landmarkResolver = CurrentLandmarkResolver()

    init(
        store: LandmarkStore,
        locationManager: UserLocationManager,
        altimeterManager: AltimeterManager
    ) {
        self.store = store
        self.locationManager = locationManager
        self.altimeterManager = altimeterManager
    }

    var cameraTitle: String {
        return store.capturedLandmarks.isEmpty
            ? "Capture Parking Spot"
            : "Capture Landmark \(store.capturedLandmarks.count)"
    }

    var cameraSubtitle: String {
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
        store.capturedLandmarks.isEmpty
    }

    var isDoneDisabled: Bool {
        store.capturedLandmarks.isEmpty
    }

    var currentCaptureLocation: CLLocation? {
        locationManager.currentCaptureLocation
    }

    func onAppear() {
        isOpeningLandmarkGallery = false
    }

    func startCaptureSession(cameraManager: CameraManager) {
        cameraManager.startSession()
        locationManager.requestAccessAndStartUpdating()
        altimeterManager.start()
    }

    func onDisappear(cameraManager: CameraManager) {
        cameraManager.stopSession()
        altimeterManager.stop()

        if !didFinishCapture && !isOpeningLandmarkGallery {
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
        showLandmarksOverlay = true
    }

    func capturePhoto(
        using cameraManager: CameraManager,
        shouldShowFirstPhotoAlert: Bool
    ) {
        guard let captureLocation = currentCaptureLocation else {
            locationManager.requestAccessAndStartUpdating()
            return
        }

        cameraManager.takePhoto(location: captureLocation) { [weak self] image, location in
            self?.saveCapturedLandmark(
                image: image,
                location: location,
                shouldShowFirstPhotoAlert: shouldShowFirstPhotoAlert
            )
        }
    }

    func cancelCapture(onPop: () -> Void) {
        store.clearParkingSpot()
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
        shouldShowFirstPhotoAlert: Bool
    ) {
        guard !isSavingPreviewLandmark else { return }

        isSavingPreviewLandmark = true
        let altitude = altimeterManager.currentSample()
        let landmarkID = store.addLandmark(
            image,
            location: location,
            landmark: .loading,
            altitude: altitude
        )
        isSavingPreviewLandmark = false

        if shouldShowFirstPhotoAlert {
            showFirstPhotoAlert = true
        }

        let resolver = landmarkResolver
        let landmarkStore = store

        Task { @MainActor in
            let landmark = await resolver.landmark(near: location)
            landmarkStore.updateCapturedLandmark(id: landmarkID, landmark: landmark)
        }
    }
}

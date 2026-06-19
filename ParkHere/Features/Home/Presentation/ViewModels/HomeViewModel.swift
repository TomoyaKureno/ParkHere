//
//  HomeViewModel.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 18/06/26.
//

import Combine
import CoreLocation
import UIKit

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var showClearParkingSpotAlert = false

    private let store: LandmarkStore
    private let locationManager: UserLocationManager

    init(store: LandmarkStore, locationManager: UserLocationManager) {
        self.store = store
        self.locationManager = locationManager
    }

    var isLocationUnavailable: Bool {
        locationManager.authorizationStatus == .denied
            || locationManager.authorizationStatus == .restricted
    }

    var currentLandmark: CurrentLandmark {
        locationManager.currentLandmark
    }

    var parkingSpot: ParkingLandmark? {
        guard store.hasCompletedParkingCapture else { return nil }

        return store.capturedLandmarks.first
    }

    func onAppear() {
        locationManager.requestAccessAndStartUpdating()
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }

        UIApplication.shared.open(url)
    }

    func requestReplaceParkingSpot() {
        showClearParkingSpotAlert = true
    }

    func confirmReplaceParkingSpot(onSaveParkingSpot: () -> Void) {
        store.clearParkingSpot()
        showClearParkingSpotAlert = false
        onSaveParkingSpot()
    }

    func saveParkingSpot(onSaveParkingSpot: () -> Void) {
        store.clearLandmarks()
        onSaveParkingSpot()
    }
}

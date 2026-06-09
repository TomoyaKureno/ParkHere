//
//  MotionPermissionService.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 08/06/26.
//

import CoreMotion
import Observation
import UIKit

@MainActor
@Observable
final class MotionPermissionService {
    enum Status { case unknown, notDetermined, authorized, denied, restricted }
    
    private(set) var status: Status = .unknown
    private let altimeter = CMAltimeter()
    
    // MARK: - Function for checking Motion Permission
    func refreshStatus() {
        switch CMAltimeter.authorizationStatus() {
        case .notDetermined: status = .notDetermined
        case .authorized: status = .authorized
        case .denied: status = .denied
        case .restricted: status = .restricted
        @unknown default: status = .unknown
        }
    }
    
    func requestIfNeeded() async {
        guard status == .notDetermined else { return }
        await withCheckedContinuation { continuation in
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] _, _ in
                self?.altimeter.stopRelativeAltitudeUpdates()
                continuation.resume()
            }
        }
        refreshStatus()
    }
    
    var canRecordAltitude: Bool { status == .authorized }
    var settingsURL: URL { URL(string: UIApplication.openSettingsURLString)! }
}

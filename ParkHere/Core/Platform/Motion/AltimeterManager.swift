//
//  AltimeterManager.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 12/06/26.
//

import Foundation
import CoreMotion
import Combine

@MainActor
final class AltimeterManager: ObservableObject {
    @Published private(set) var relativeAltitude: Double?
    @Published private(set) var absoluteAltitude: Double?
    @Published private(set) var pressureKPa: Double?
    @Published private(set) var authoriztionStatus: CMAuthorizationStatus = CMAltimeter.authorizationStatus()
    @Published private(set) var isAvailable: Bool = CMAltimeter.isRelativeAltitudeAvailable()
    
    private let altimeter = CMAltimeter()
    private let queue = OperationQueue()
    private var isRunning: Bool = false
    
    var isMotionAccessGranted: Bool { authoriztionStatus == .authorized }
    var isMotionAccessDenied: Bool {
        authoriztionStatus == .denied || authoriztionStatus == .restricted
    }
    
    func start() {
        guard !isRunning else { return }
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            isAvailable = false
            return
        }
        isRunning = true
        
        altimeter.startRelativeAltitudeUpdates(to: queue) { [weak self] data, _ in
            guard let data else { return }
            let relative = data.relativeAltitude.doubleValue
            let pressure = data.pressure.doubleValue
            
            Task { @MainActor in
                self?.relativeAltitude = relative
                self?.pressureKPa = pressure
                self?.authoriztionStatus = CMAltimeter.authorizationStatus()
            }
        }
        
        if CMAltimeter.isAbsoluteAltitudeAvailable() {
            altimeter.startAbsoluteAltitudeUpdates(to: queue) { [weak self] data, _ in
                let absolute = data?.altitude
                Task{ @MainActor in
                    self?.absoluteAltitude = absolute
                }
            }
        }
    }
    
    func stop() {
        guard isRunning else { return }
        isRunning = false
        altimeter.stopRelativeAltitudeUpdates()
        altimeter.stopAbsoluteAltitudeUpdates()
    }
    
    func currentSample() -> AltitudeSample? {
        guard relativeAltitude != nil || absoluteAltitude != nil else { return nil }
        return AltitudeSample(
            absoluteAltitude: absoluteAltitude,
            pressureKPa: pressureKPa,
            relativeAltitude: relativeAltitude,
            capturedAt: Date()
        )
    }
}

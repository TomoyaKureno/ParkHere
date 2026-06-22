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
    @Published private(set) var absoluteAltitudeAccuracy: Double?
    @Published private(set) var pressureKPa: Double?
    @Published private(set) var authorizationStatus: CMAuthorizationStatus = CMAltimeter.authorizationStatus()
    @Published private(set) var isAvailable: Bool = CMAltimeter.isRelativeAltitudeAvailable()

    /// Stable identifier for this app session. A new UUID is created every app launch,
    /// enabling reliable cross-session detection without any persistence.
    let sessionID = UUID()

    /// Barometric pressure (kPa) recorded at the very first update of this session.
    /// Used as an absolute pressure anchor for cross-session floor delta estimation.
    private(set) var sessionStartPressure: Double?

    private let altimeter = CMAltimeter()
    private let queue = OperationQueue()

    /// Reference count — each caller that needs altitude increments on start()
    /// and decrements on stop(). The altimeter only truly stops when count reaches 0,
    /// preventing relativeAltitude from resetting between view transitions.
    private var retainCount = 0

    var isMotionAccessDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func start() {
        retainCount += 1
        guard retainCount == 1 else { return }

        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            isAvailable = false
            return
        }

        altimeter.startRelativeAltitudeUpdates(to: queue) { [weak self] data, error in
            guard let data else {
                Task { @MainActor in
                    self?.authorizationStatus = CMAltimeter.authorizationStatus()
                }
                return
            }

            let relative = data.relativeAltitude.doubleValue
            let pressure = data.pressure.doubleValue

            Task { @MainActor in
                if self?.sessionStartPressure == nil {
                    self?.sessionStartPressure = pressure
                }
                self?.relativeAltitude = relative
                self?.pressureKPa = pressure
                self?.authorizationStatus = CMAltimeter.authorizationStatus()
            }
        }

        if CMAltimeter.isAbsoluteAltitudeAvailable() {
            altimeter.startAbsoluteAltitudeUpdates(to: queue) { [weak self] data, error in
                guard let data, data.accuracy >= 0 else { return }

                let altitude = data.altitude
                let accuracy = data.accuracy

                Task { @MainActor in
                    self?.absoluteAltitude = altitude
                    self?.absoluteAltitudeAccuracy = accuracy
                }
            }
        }
    }

    func stop() {
        retainCount = max(0, retainCount - 1)
        guard retainCount == 0 else { return }

        altimeter.stopRelativeAltitudeUpdates()
        altimeter.stopAbsoluteAltitudeUpdates()

        sessionStartPressure = nil
        relativeAltitude = nil
        absoluteAltitude = nil
        absoluteAltitudeAccuracy = nil
        pressureKPa = nil
    }

    func currentSample() -> AltitudeSample? {
        guard relativeAltitude != nil || absoluteAltitude != nil else { return nil }

        return AltitudeSample(
            absoluteAltitude: absoluteAltitude,
            absoluteAltitudeAccuracy: absoluteAltitudeAccuracy,
            pressureKPa: pressureKPa,
            relativeAltitude: relativeAltitude,
            sessionID: sessionID,
            capturedAt: Date()
        )
    }
}

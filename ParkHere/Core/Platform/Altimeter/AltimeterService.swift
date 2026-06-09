//
//  AltimeterService.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 08/06/26.
//

import CoreMotion
import Observation

@MainActor
@Observable
final class AltimeterService {
    struct Reading {
        let altitude: Double?
        let accuracy: Double?
        let precision: Double?
        let pressureKpa: Double?
        let isLowConfidence: Bool
        let capturedAt: Date
    }
    
    private let altimeter = CMAltimeter()
    let isAbsoluteAvailable = CMAltimeter.isAbsoluteAltitudeAvailable()
    
    func captureReading(
        samples: Int = 5,
        floorHeight: Double = 3.0,
        timeout: Duration = .seconds(8)
    ) async throws -> Reading {
        var altitudeSamples: [Double] = []
        var bestAccuracy: Double = .infinity
        var bestPrecision: Double = .infinity
        var pressure: Double?
        let deadline = Date.now.addingTimeInterval(Double(timeout.components.seconds))
        let accuracyThreshold: Double = floorHeight * AltimeterConstants.deadbandFactor
        
        // Kumpulkan pressure paralel dari relative updates
        altimeter.startRelativeAltitudeUpdates(to: .main) { data, _ in
            if let p = data?.pressure.doubleValue {
                pressure = p
                self.altimeter.stopRelativeAltitudeUpdates()
            }
        }

        // Kumpulkan N sampel absolute
        var isLow = false
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            altimeter.startAbsoluteAltitudeUpdates(to: .main) { data, error in
                if let error {
                    self.altimeter.stopAbsoluteAltitudeUpdates()
                    cont.resume(throwing: error)
                    return
                }
                guard let data else { return }

                altitudeSamples.append(data.altitude)
                bestAccuracy = min(bestAccuracy, data.accuracy)
                bestPrecision = min(bestPrecision, data.precision)

                let hasEnoughSamples = altitudeSamples.count >= samples
                let isGoodQuality = bestAccuracy <= accuracyThreshold
                let isTimedOut = Date.now >= deadline

                if hasEnoughSamples && (isGoodQuality || isTimedOut) {
                    isLow = !isGoodQuality
                    self.altimeter.stopAbsoluteAltitudeUpdates()
                    cont.resume()
                } else if isTimedOut {
                    isLow = true
                    self.altimeter.stopAbsoluteAltitudeUpdates()
                    cont.resume()
                }
            }
        }

        let avgAltitude = altitudeSamples.isEmpty ? nil
            : altitudeSamples.reduce(0, +) / Double(altitudeSamples.count)

        return Reading(
            altitude: avgAltitude,
            accuracy: bestAccuracy == .infinity ? nil : bestAccuracy,
            precision: bestPrecision == .infinity ? nil : bestPrecision,
            pressureKpa: pressure,
            isLowConfidence: isLow,
            capturedAt: .now
        )
    }
}

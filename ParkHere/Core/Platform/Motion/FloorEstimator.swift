//
//  FloorEstimator.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 14/06/26.
//

import Foundation

struct FloorEstimator {
    var floorHeight: Double = 3.0
    // Increased from 0.6 to 1.0 (33% of floorHeight) to create a wider dead-band
    // around each floor boundary, making the estimator more tolerant of sensor
    // noise and the ±1–2m accuracy typical of absoluteAltitude readings.
    var hysteresis: Double = 1.0

    func floors(deltaMeters: Double, previousFloors: Int) -> Int {
        let raw = deltaMeters / floorHeight
        let distanceFromPrevious = abs(raw - Double(previousFloors))
        guard distanceFromPrevious >= hysteresis else { return previousFloors }
        return Int(raw.rounded())
    }

    func shortLabel(_ floors: Int) -> String {
        floors == 0 ? "Same Floor" : "\(abs(floors)) Floor \(floors > 0 ? "Above" : "Below")"
    }

    func icon(_ floors: Int) -> String {
        if floors == 0 { return "equal" }
        return floors > 0 ? "arrow.up" : "arrow.down"
    }
}

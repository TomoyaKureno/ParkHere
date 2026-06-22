//
//  FloorEstimator.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 14/06/26.
//

import Foundation

struct FloorEstimator {
    var floorHeight: Double = 3.0
    var hysteresis: Double = 0.6

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

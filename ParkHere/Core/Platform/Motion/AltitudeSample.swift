//
//  AltitudeSample.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 12/06/26.
//

import Foundation

struct AltitudeSample: Equatable {
    let absoluteAltitude: Double?
    let absoluteAltitudeAccuracy: Double?
    let pressureKPa: Double?
    let relativeAltitude: Double?
    let sessionID: UUID
    let capturedAt: Date
}

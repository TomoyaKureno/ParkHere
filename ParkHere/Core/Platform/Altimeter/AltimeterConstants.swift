//
//  AltimeterConstants.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 08/06/26.
//

import Foundation

enum AltimeterConstants {
    static let floorHeight: Double = 3.0
    static let sampleCount: Int = 5
    static let captureTimeout: Duration = .seconds(8)
    static let deadbandFactor: Double = 0.5
    
    enum FusionWeight {
        static let absolute: Double = 0.55
        static let pedometer: Double = 0.30
        static let pressure: Double = 0.15
        static let pressureDriftPenalty: Double = 0.5
    }
}

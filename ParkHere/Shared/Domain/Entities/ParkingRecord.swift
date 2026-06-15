//
//  ParkingRecord.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 12/06/26.
//

import Foundation
import SwiftData

@Model
final class ParkingRecord {
    var latitude: Double?
    var longitude: Double?
    var horizontalAccuracy: Double?
    
    var absoluteAltitude: Double?
    var pressureKPa: Double?
    var relativeAltitude: Double?
    
    var createdAt: Date
    
    init (
        latitude: Double? = nil,
        longitude: Double? = nil,
        horizontalAccuracy: Double? = nil,
        absoluteAltitude: Double? = nil,
        pressureKPa: Double? = nil,
        relativeAltitude: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.absoluteAltitude = absoluteAltitude
        self.pressureKPa = pressureKPa
        self.relativeAltitude = relativeAltitude
        self.createdAt = createdAt
    }
}

//
//  LandmarkRecord.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 16/06/26.
//

import Foundation
import SwiftData

@Model
final class LandmarkRecord {
    var id: UUID
    var orderIndex: Int
    var imageFileName: String
    var latitude: Double?
    var longitude: Double?
    var horizontalAccuracy: Double?
    var landmarkTitle: String
    var landmarkSubtitle: String
    var absoluteAltitude: Double?
    var pressureKPa: Double?
    var relativeAltitude: Double?
    var capturedAt: Date

    init(
        id: UUID,
        orderIndex: Int,
        imageFileName: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        horizontalAccuracy: Double? = nil,
        landmarkTitle: String,
        landmarkSubtitle: String,
        absoluteAltitude: Double? = nil,
        pressureKPa: Double? = nil,
        relativeAltitude: Double? = nil,
        capturedAt: Date
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.imageFileName = imageFileName
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.landmarkTitle = landmarkTitle
        self.landmarkSubtitle = landmarkSubtitle
        self.absoluteAltitude = absoluteAltitude
        self.pressureKPa = pressureKPa
        self.relativeAltitude = relativeAltitude
        self.capturedAt = capturedAt
    }
}

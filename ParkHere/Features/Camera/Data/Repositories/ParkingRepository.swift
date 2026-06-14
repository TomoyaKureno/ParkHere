//
//  ParkingRepository.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 14/06/26.
//

import Foundation
import CoreLocation
import SwiftData

@MainActor
final class ParkingRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch ParkingRecord data from SwiftData
    func loadActive() -> ParkingRecord? {
        var descriptor = FetchDescriptor<ParkingRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
    
    func save(
        coordinate: CLLocationCoordinate2D?,
        horizontalAccuracy: Double?,
        altitude: AltitudeSample?
    ) {
        clear()
        
        let record = ParkingRecord(
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude,
            horizontalAccuracy: horizontalAccuracy,
            absoluteAltitude: altitude?.absoluteAltitude,
            pressureKPa: altitude?.pressureKPa,
            relativeAltitude: altitude?.relativeAltitude,
        )
        
        modelContext.insert(record)
        try? modelContext.save()
    }
    
    func clear() {
        try? modelContext.delete(model: ParkingRecord.self)
        try? modelContext.save()
    }
}

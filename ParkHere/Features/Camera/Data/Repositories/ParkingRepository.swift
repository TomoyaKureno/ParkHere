//
//  ParkingRepository.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 14/06/26.
//

import Foundation
import CoreLocation
import SwiftData
import UIKit

@MainActor
final class ParkingRepository {
    private let modelContext: ModelContext
    private let fileManager: FileManager
    private let imageDirectoryName = "WaypointImages"
    
    init(modelContext: ModelContext, fileManager: FileManager = .default) {
        self.modelContext = modelContext
        self.fileManager = fileManager
    }

    func loadWaypoints() -> [ParkingWaypoint] {
        let descriptor = FetchDescriptor<WaypointRecord>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )

        guard let records = try? modelContext.fetch(descriptor) else { return [] }

        return records.compactMap { record in
            guard let image = loadImage(fileName: record.imageFileName) else { return nil }

            let location = makeLocation(from: record)
            let altitude = makeAltitude(from: record)
            let landmark = CurrentLandmark(
                title: record.landmarkTitle,
                subtitle: record.landmarkSubtitle
            )

            return ParkingWaypoint(
                id: record.id,
                image: image,
                location: location,
                landmark: landmark,
                altitude: altitude,
                capturedAt: record.capturedAt
            )
        }
    }

    func saveWaypoints(_ waypoints: [ParkingWaypoint]) {
        clearWaypointRecords()

        let activeImageFileNames = Set(waypoints.map { imageFileName(for: $0.id) })

        for (index, waypoint) in waypoints.enumerated() {
            let imageFileName = imageFileName(for: waypoint.id)
            saveImage(waypoint.image, fileName: imageFileName)

            let record = WaypointRecord(
                id: waypoint.id,
                orderIndex: index,
                imageFileName: imageFileName,
                latitude: waypoint.latitude,
                longitude: waypoint.longitude,
                horizontalAccuracy: waypoint.horizontalAccuracy,
                landmarkTitle: waypoint.landmark.title,
                landmarkSubtitle: waypoint.landmark.subtitle,
                absoluteAltitude: waypoint.altitude?.absoluteAltitude,
                pressureKPa: waypoint.altitude?.pressureKPa,
                relativeAltitude: waypoint.altitude?.relativeAltitude,
                capturedAt: waypoint.capturedAt
            )
            modelContext.insert(record)
        }

        deleteOrphanedImages(activeFileNames: activeImageFileNames)
        try? modelContext.save()
    }
    
    func clear() {
        clearWaypoints()
    }

    func clearWaypoints() {
        clearWaypointRecords()
        deleteImageDirectory()
        try? modelContext.save()
    }

    private func clearWaypointRecords() {
        try? modelContext.delete(model: WaypointRecord.self)
    }

    private func imageFileName(for id: UUID) -> String {
        "\(id.uuidString).jpg"
    }

    private func makeLocation(from record: WaypointRecord) -> CLLocation? {
        guard let latitude = record.latitude, let longitude = record.longitude else { return nil }

        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: record.absoluteAltitude ?? 0,
            horizontalAccuracy: record.horizontalAccuracy ?? -1,
            verticalAccuracy: -1,
            timestamp: record.capturedAt
        )
    }

    private func makeAltitude(from record: WaypointRecord) -> AltitudeSample? {
        guard record.absoluteAltitude != nil || record.pressureKPa != nil || record.relativeAltitude != nil else {
            return nil
        }

        return AltitudeSample(
            absoluteAltitude: record.absoluteAltitude,
            pressureKPa: record.pressureKPa,
            relativeAltitude: record.relativeAltitude,
            capturedAt: record.capturedAt
        )
    }

    private func saveImage(_ image: UIImage, fileName: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else { return }

        do {
            let directoryURL = try imageDirectoryURL()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try imageData.write(to: directoryURL.appendingPathComponent(fileName), options: .atomic)
        } catch {
            assertionFailure("Failed to save waypoint image: \(error)")
        }
    }

    private func loadImage(fileName: String) -> UIImage? {
        guard
            let directoryURL = try? imageDirectoryURL(),
            let imageData = try? Data(contentsOf: directoryURL.appendingPathComponent(fileName))
        else { return nil }

        return UIImage(data: imageData)
    }

    private func deleteOrphanedImages(activeFileNames: Set<String>) {
        guard
            let directoryURL = try? imageDirectoryURL(),
            let fileURLs = try? fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil
            )
        else { return }

        for fileURL in fileURLs where !activeFileNames.contains(fileURL.lastPathComponent) {
            try? fileManager.removeItem(at: fileURL)
        }
    }

    private func deleteImageDirectory() {
        guard let directoryURL = try? imageDirectoryURL() else { return }

        try? fileManager.removeItem(at: directoryURL)
    }

    private func imageDirectoryURL() throws -> URL {
        try fileManager
            .url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent(imageDirectoryName, isDirectory: true)
    }
}

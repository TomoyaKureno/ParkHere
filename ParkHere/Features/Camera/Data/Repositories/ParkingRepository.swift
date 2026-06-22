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
    private let imageDirectoryName = "LandmarkImages"
    
    init(modelContext: ModelContext, fileManager: FileManager = .default) {
        self.modelContext = modelContext
        self.fileManager = fileManager
    }

    func loadLandmarks() -> [ParkingLandmark] {
        let descriptor = FetchDescriptor<LandmarkRecord>(
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

            return ParkingLandmark(
                id: record.id,
                image: image,
                location: location,
                landmark: landmark,
                altitude: altitude,
                capturedAt: record.capturedAt
            )
        }
    }

    func saveLandmarks(_ landmarks: [ParkingLandmark]) {
        clearLandmarkRecords()

        let activeImageFileNames = Set(landmarks.map { imageFileName(for: $0.id) })

        for (index, landmark) in landmarks.enumerated() {
            let imageFileName = imageFileName(for: landmark.id)
            saveImage(landmark.image, fileName: imageFileName)

            let record = LandmarkRecord(
                id: landmark.id,
                orderIndex: index,
                imageFileName: imageFileName,
                latitude: landmark.latitude,
                longitude: landmark.longitude,
                horizontalAccuracy: landmark.horizontalAccuracy,
                landmarkTitle: landmark.landmark.title,
                landmarkSubtitle: landmark.landmark.subtitle,
                absoluteAltitude: landmark.altitude?.absoluteAltitude,
                absoluteAltitudeAccuracy: landmark.altitude?.absoluteAltitudeAccuracy,
                pressureKPa: landmark.altitude?.pressureKPa,
                relativeAltitude: landmark.altitude?.relativeAltitude,
                altitudeSessionID: landmark.altitude?.sessionID,
                capturedAt: landmark.capturedAt
            )
            modelContext.insert(record)
        }

        deleteOrphanedImages(activeFileNames: activeImageFileNames)
        try? modelContext.save()
    }
    
    func clearLandmarks() {
        clearLandmarkRecords()
        deleteImageDirectory()
        try? modelContext.save()
    }

    private func clearLandmarkRecords() {
        try? modelContext.delete(model: LandmarkRecord.self)
    }

    private func imageFileName(for id: UUID) -> String {
        "\(id.uuidString).jpg"
    }

    private func makeLocation(from record: LandmarkRecord) -> CLLocation? {
        guard let latitude = record.latitude, let longitude = record.longitude else { return nil }

        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: record.absoluteAltitude ?? 0,
            horizontalAccuracy: record.horizontalAccuracy ?? -1,
            verticalAccuracy: -1,
            timestamp: record.capturedAt
        )
    }

    private func makeAltitude(from record: LandmarkRecord) -> AltitudeSample? {
        guard record.absoluteAltitude != nil || record.pressureKPa != nil || record.relativeAltitude != nil else {
            return nil
        }

        return AltitudeSample(
            absoluteAltitude: record.absoluteAltitude,
            absoluteAltitudeAccuracy: record.absoluteAltitudeAccuracy,
            pressureKPa: record.pressureKPa,
            relativeAltitude: record.relativeAltitude,
            sessionID: record.altitudeSessionID ?? UUID(),
            capturedAt: record.capturedAt
        )
    }

    private func saveImage(_ image: UIImage, fileName: String) {
        guard let directoryURL = try? imageDirectoryURL() else { return }
        let fileURL = directoryURL.appendingPathComponent(fileName)

        guard !fileManager.fileExists(atPath: fileURL.path) else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.85) else { return }

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try imageData.write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Failed to save landmark image: \(error)")
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

//
//  LandmarksViewModel.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 18/06/26.
//

import Combine
import SwiftUI

@MainActor
final class LandmarksViewModel: ObservableObject {
    @Published var selectedDetail: LandmarkDetail?
    @Published var deleteRequest: LandmarkDeleteRequest?

    private let store: LandmarkStore
    private let isGallery: Bool

    init(
        store: LandmarkStore,
        isGallery: Bool
    ) {
        self.store = store
        self.isGallery = isGallery
    }

    var orderedLandmarkIndices: [Int] {
        Array(store.capturedLandmarks.indices.reversed())
    }

    var photoCountText: String {
        "\(store.capturedLandmarks.count) Photos"
    }

    var isDeleteAlertPresented: Bool {
        deleteRequest != nil
    }

    func setDeleteAlertPresented(_ isPresented: Bool) {
        if !isPresented {
            deleteRequest = nil
        }
    }

    func isLandmarkRetakeNeeded(at index: Int) -> Bool {
        store.isLandmarkRetakeNeeded(at: index)
    }

    func requestDelete(at landmarkIndex: Int) {
        deleteRequest = LandmarkDeleteRequest(
            landmarkIndex: landmarkIndex,
            title: "Delete \(landmarkLabel(for: landmarkIndex).text)"
        )
    }

    func showDetail(for landmarkIndex: Int, visualIndex: Int) {
        guard !isGallery else { return }
        guard !store.isLandmarkRetakeNeeded(at: landmarkIndex) else { return }
        guard store.capturedLandmarks.indices.contains(landmarkIndex) else { return }
        let selectionState = store.landmarkSelectionState(for: landmarkIndex)
        guard selectionState != .passed else { return }

        let landmark = store.capturedLandmarks[landmarkIndex]
        selectedDetail = LandmarkDetail(
            landmarkIndex: landmarkIndex,
            image: landmark.image,
            title: landmarkLabel(for: landmarkIndex).text,
            subtitle: landmark.landmark.title,
            progressText: "\(visualIndex + 1) of \(orderedLandmarkIndices.count) points",
            selectionState: selectionState
        )
    }

    func landmarkLabel(for landmarkIndex: Int) -> LandmarkBadgeInfo {
        guard
            let firstIndex = store.capturedLandmarks.indices.first,
            let lastIndex = store.capturedLandmarks.indices.last
        else {
            return LandmarkBadgeInfo(text: "Landmark", color: .blue)
        }

        if landmarkIndex == lastIndex {
            return LandmarkBadgeInfo(text: "Final Spot", color: .green)
        }

        if landmarkIndex == firstIndex {
            return LandmarkBadgeInfo(text: "Parking Spot", color: .blue)
        }

        return LandmarkBadgeInfo(text: "Landmark \(landmarkIndex)", color: .blue)
    }

    func confirmDelete() {
        guard let deleteRequest else { return }

        store.markLandmarkForRetake(at: deleteRequest.landmarkIndex)
        self.deleteRequest = nil
    }

    func handleBack(onTapBack: () -> Void) {
        if isGallery {
            store.removeRetakeLandmarks()
        }

        onTapBack()
    }
}

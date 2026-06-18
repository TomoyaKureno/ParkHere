//
//  LandmarksView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 15/06/26.
//

import SwiftUI

struct LandmarksView: View {
    @ObservedObject var store: LandmarkStore

    let isGallery: Bool
    let currentLandmarkIndex: Int
    let onTapBack: () -> Void
    let onUseLandmark: (Int) -> Void
    let onRetakeLandmark: (Int) -> Void

    @State private var selectedDetail: LandmarkDetail?
    @State private var deleteRequest: LandmarkDeleteRequest?

    private var orderedLandmarkIndices: [Int] {
        let indices = Array(store.capturedLandmarks.indices)
        return Array(indices.reversed())
    }

    var body: some View {
        ZStack {
            Color.surfacePrimaryBlack.ignoresSafeArea()

            VStack(spacing: 8) {
                header

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(orderedLandmarkIndices.enumerated()), id: \.element) { visualIndex, landmarkIndex in
                            LandmarkImageView(
                                isGallery: isGallery,
                                image: store.capturedLandmarks[landmarkIndex].image,
                                isRetakeNeeded: store.isLandmarkRetakeNeeded(at: landmarkIndex),
                                visualIndex: visualIndex,
                                label: landmarkLabel(for: landmarkIndex),
                                currentLandmarkIndex: currentLandmarkIndex,
                                onDelete: {
                                    deleteRequest = LandmarkDeleteRequest(
                                        landmarkIndex: landmarkIndex,
                                        title: "Delete \(landmarkLabel(for: landmarkIndex).text)"
                                    )
                                },
                                onRetake: {
                                    onRetakeLandmark(landmarkIndex)
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showDetail(for: landmarkIndex, visualIndex: visualIndex)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .sheet(item: $selectedDetail) { detail in
            LandmarkDetailSheet(detail: detail) {
                guard detail.selectionState.canUseLandmark else { return }

                selectedDetail = nil
                onUseLandmark(detail.landmarkIndex)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert(
            deleteRequest?.title ?? "",
            isPresented: deleteAlertBinding
        ) {
            Button("No", role: .cancel) {
                deleteRequest = nil
            }

            Button("Yes", role: .destructive) {
                confirmDelete()
            }
        } message: {
            Text("Are you sure you want to delete this landmark?")
        }
    }

    private var header: some View {
        HStack {
            VStack {
                Text("Your Landmarks")
                    .font(.headline)
                Text("\(store.capturedLandmarks.count) Photos")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .leading) {
            Button(action: handleBack) {
                Image(systemName: AppIcon.chevronLeft)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .glassEffect(.regular, in: Circle())
            .padding(.horizontal, 12)
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { deleteRequest != nil },
            set: { isPresented in
                if !isPresented {
                    deleteRequest = nil
                }
            }
        )
    }

    private func showDetail(for landmarkIndex: Int, visualIndex: Int) {
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

    private func landmarkLabel(for landmarkIndex: Int) -> LandmarkBadgeInfo {
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

    private func confirmDelete() {
        guard let deleteRequest else { return }

        store.markLandmarkForRetake(at: deleteRequest.landmarkIndex)
        self.deleteRequest = nil
    }

    private func handleBack() {
        if isGallery {
            store.removeRetakeLandmarks()
        }

        onTapBack()
    }
}

private struct LandmarkImageView: View {
    let isGallery: Bool
    let image: UIImage
    let isRetakeNeeded: Bool
    let visualIndex: Int
    let label: LandmarkBadgeInfo
    let currentLandmarkIndex: Int
    let onDelete: () -> Void
    let onRetake: () -> Void

    var isParkingSpot: Bool {
        label.text == "Parking Spot"
    }

    private var landmarkCircleIndex: Int {
        visualIndex + 1
    }

    private var glassEffect: Glass {
        ((visualIndex < currentLandmarkIndex) || (visualIndex == currentLandmarkIndex && isParkingSpot)) && !isGallery
            ? Glass.regular.tint(.blue.opacity(0.7))
            : Glass.regular
    }

    var body: some View {
        if visualIndex == currentLandmarkIndex, !isGallery {
            VStack(spacing: 8) {
                HStack {
                    landmarkIndexCircle

                    VStack(alignment: .leading) {
                        Text(isParkingSpot ? "You've Arrived" : "You're now heading to")
                        if !isParkingSpot {
                            Text("Next nearest Landmark")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(isParkingSpot ? .headline : .footnote.weight(.semibold))
                }
                .frame(width: 200)

                HStack(spacing: 14) {
                    if isParkingSpot {
                        Capsule()
                            .fill(.clear)
                            .frame(width: 20)
                            .glassEffect(glassEffect, in: Capsule())
                    }

                    landmarkImage
                        .padding(.bottom, 8)
                        .padding(.leading, isParkingSpot ? 0 : 40)
                }
                .padding(.leading, isParkingSpot ? 7 : 0)
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
            .frame(height: 280)
        } else {
            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: 4) {
                    landmarkIndexCircle

                    if visualIndex < currentLandmarkIndex, !isGallery {
                        Capsule()
                            .fill(.clear)
                            .frame(width: 20)
                            .glassEffect(glassEffect, in: Capsule())
                    }
                }

                landmarkImage
                    .padding(.top, 4)
                    .padding(.bottom, 8)
            }
            .frame(height: 240)
        }
    }

    private var landmarkIndexCircle: some View {
        Text("\(landmarkCircleIndex)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .glassEffect(glassEffect, in: Circle())
    }

    @ViewBuilder
    private var landmarkImage: some View {
        if isRetakeNeeded {
            LandmarkRetakePlaceholder(onRetake: onRetake)
                .frame(width: 160)
                .frame(maxHeight: .infinity)
        } else {
                AdaptiveImageView(
                    uiImage: image,
                    width: 160,
                    height: 240,
                    cornerRadius: 8
                )
                .overlay(alignment: .topLeading) {
                    LandmarkBadge(
                        text: label.text,
                        color: label.color
                    )
                }
                .overlay(alignment: .topTrailing) {
                    if isGallery {
                        Button(action: onDelete) {
                            Image(systemName: AppIcon.xMark)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.black)
                                .padding(4)
                                .background(.gray)
                                .clipShape(Circle())
                        }
                        .offset(x: 6, y: -6)
                    }
                }
                .overlay {
                    if visualIndex < currentLandmarkIndex, !isGallery {
                        Color.white.opacity(0.3)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
        }
    }
}

private struct LandmarkRetakePlaceholder: View {
    let onRetake: () -> Void

    var body: some View {
        Button(action: onRetake) {
            VStack(spacing: 8) {
                Image(systemName: AppIcon.camera)
                    .font(.title3.weight(.semibold))
                Text("Retake the photo")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.72))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.7), lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct LandmarkDetailSheet: View {
    let detail: LandmarkDetail
    let onUseLandmark: () -> Void

    var body: some View {
        ZStack {
            Color.surfaceSecondaryBlackSmoke.ignoresSafeArea()

            VStack(spacing: 28) {
                Text(detail.progressText)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 16)

                imageSection

                VStack(alignment: .leading, spacing: 6) {
                    Text(detail.title)
                        .font(.title3Bold)
                        .foregroundStyle(.white)

                    Text(detail.subtitle)
                        .font(.bodyBold)
                        .foregroundStyle(.white.opacity(0.22))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                Button {
                    onUseLandmark()
                } label: {
                    Text(detail.selectionState.buttonTitle)
                }
                .buttonStyle(.primaryStyle)
                .disabled(!detail.selectionState.canUseLandmark)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
    }

    private var imageSection: some View {
        AdaptiveImageView(
            uiImage: detail.image,
            width: nil,
            height: 500,
            cornerRadius: 8,
        )
    }
}

private struct LandmarkDetail: Identifiable {
    let landmarkIndex: Int
    let image: UIImage
    let title: String
    let subtitle: String
    let progressText: String
    let selectionState: LandmarkSelectionState

    var id: Int {
        landmarkIndex
    }
}

private extension LandmarkSelectionState {
    var canUseLandmark: Bool {
        self == .available
    }

    var buttonTitle: String {
        switch self {
        case .available:
            return "Go to This Landmark Instead"
        case .current:
            return "Current Landmark"
        case .passed:
            return "Already Passed"
        case .unavailable:
            return "Unavailable"
        }
    }
}

private struct LandmarkDeleteRequest {
    let landmarkIndex: Int
    let title: String
}

private struct LandmarkBadgeInfo {
    let text: String
    let color: Color
}

#Preview {
    let store = LandmarkStore()
    store.addLandmark(UIImage(resource: .imgLandmark), location: nil)
    store.addLandmark(UIImage(resource: .imgLandmark), location: nil)
    store.addLandmark(UIImage(resource: .imgLandmark), location: nil)
    store.addLandmark(UIImage(resource: .imgLandmark), location: nil)

    return LandmarksView(
        store: store,
        isGallery: false,
        currentLandmarkIndex: 3
    ) {} onUseLandmark: { _ in
    } onRetakeLandmark: { _ in
    }
    .preferredColorScheme(.dark)
}

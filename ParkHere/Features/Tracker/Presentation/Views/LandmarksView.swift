//
//  LandmarksView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 15/06/26.
//

import SwiftUI

struct LandmarksView: View {
    @ObservedObject var store: WaypointStore

    let isGallery: Bool
    let currentLandmarkIndex: Int
    let onTapBack: () -> Void
    let onUseLandmark: (Int) -> Void
    let onRetakeLandmark: (Int) -> Void

    @State private var selectedDetail: LandmarkDetail?
    @State private var deleteRequest: LandmarkDeleteRequest?

    private var orderedWaypointIndices: [Int] {
        let indices = Array(store.capturedWaypoints.indices)
        return Array(indices.reversed())
    }

    var body: some View {
        ZStack {
            Color.surfacePrimaryBlack.ignoresSafeArea()

            VStack(spacing: 8) {
                header

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(orderedWaypointIndices.enumerated()), id: \.element) { visualIndex, waypointIndex in
                            LandmarkImageView(
                                isGallery: isGallery,
                                image: store.capturedWaypoints[waypointIndex].image,
                                isRetakeNeeded: store.isWaypointRetakeNeeded(at: waypointIndex),
                                visualIndex: visualIndex,
                                label: landmarkLabel(for: waypointIndex),
                                landmarkCount: orderedWaypointIndices.count,
                                currentLandmarkIndex: currentLandmarkIndex,
                                onDelete: {
                                    deleteRequest = LandmarkDeleteRequest(
                                        waypointIndex: waypointIndex,
                                        title: "Delete \(landmarkLabel(for: waypointIndex).text)"
                                    )
                                },
                                onRetake: {
                                    onRetakeLandmark(waypointIndex)
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showDetail(for: waypointIndex, visualIndex: visualIndex)
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
                onUseLandmark(detail.waypointIndex)
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
                Text("\(store.capturedWaypoints.count) Photos")
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

    private func showDetail(for waypointIndex: Int, visualIndex: Int) {
        guard !isGallery else { return }
        guard !store.isWaypointRetakeNeeded(at: waypointIndex) else { return }
        guard store.capturedWaypoints.indices.contains(waypointIndex) else { return }
        let selectionState = store.landmarkSelectionState(for: waypointIndex)
        guard selectionState != .passed else { return }

        let waypoint = store.capturedWaypoints[waypointIndex]
        selectedDetail = LandmarkDetail(
            waypointIndex: waypointIndex,
            image: waypoint.image,
            title: landmarkLabel(for: waypointIndex).text,
            subtitle: waypoint.landmark.title,
            progressText: "\(visualIndex + 1) of \(orderedWaypointIndices.count) points",
            selectionState: selectionState
        )
    }

    private func landmarkLabel(for waypointIndex: Int) -> LandmarkLabel {
        guard
            let firstIndex = store.capturedWaypoints.indices.first,
            let lastIndex = store.capturedWaypoints.indices.last
        else {
            return LandmarkLabel(text: "Landmark", color: .blue)
        }

        if waypointIndex == lastIndex {
            return LandmarkLabel(text: "Final Spot", color: .green)
        }

        if waypointIndex == firstIndex {
            return LandmarkLabel(text: "Parking Spot", color: .blue)
        }

        return LandmarkLabel(text: "Landmark \(waypointIndex)", color: .blue)
    }

    private func confirmDelete() {
        guard let deleteRequest else { return }

        store.markWaypointForRetake(at: deleteRequest.waypointIndex)
        self.deleteRequest = nil
    }

    private func handleBack() {
        if isGallery {
            store.removeRetakeWaypoints()
        }

        onTapBack()
    }
}

private struct LandmarkImageView: View {
    let isGallery: Bool
    let image: UIImage
    let isRetakeNeeded: Bool
    let visualIndex: Int
    let label: LandmarkLabel
    let landmarkCount: Int
    let currentLandmarkIndex: Int
    let onDelete: () -> Void
    let onRetake: () -> Void

    private var landmarkCircleIndex: Int {
        visualIndex + 1
    }

    private var glassEffect: Glass {
        visualIndex < currentLandmarkIndex && !isGallery
            ? Glass.regular.tint(.blue.opacity(0.7))
            : Glass.regular
    }

    var body: some View {
        if visualIndex == currentLandmarkIndex, !isGallery {
            VStack(spacing: 8) {
                HStack {
                    landmarkIndexCircle

                    VStack(alignment: .leading) {
                        Text("You're now heading to")
                        Text("Next nearest Landmark")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.footnote.weight(.semibold))
                }
                .frame(width: 200)

                landmarkImage
                    .padding(.bottom, 8)
                    .padding(.leading, 40)
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
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 160)
                .frame(maxHeight: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topLeading) {
                    WaypointLabel(
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
        Image(uiImage: detail.image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 500)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func sheetArrowButton(icon: String) -> some View {
        Image(systemName: icon)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .glassEffect(.regular, in: Circle())
    }
}

private struct LandmarkDetail: Identifiable {
    let waypointIndex: Int
    let image: UIImage
    let title: String
    let subtitle: String
    let progressText: String
    let selectionState: LandmarkSelectionState

    var id: Int {
        waypointIndex
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
    let waypointIndex: Int
    let title: String
}

private struct LandmarkLabel {
    let text: String
    let color: Color
}

#Preview {
    let store = WaypointStore()
    store.addWaypoint(UIImage(resource: .imgWaypoint), location: nil)
    store.addWaypoint(UIImage(resource: .imgWaypoint), location: nil)
    store.addWaypoint(UIImage(resource: .imgWaypoint), location: nil)
    store.addWaypoint(UIImage(resource: .imgWaypoint), location: nil)

    return LandmarksView(
        store: store,
        isGallery: true,
        currentLandmarkIndex: 3
    ) {} onUseLandmark: { _ in
    } onRetakeLandmark: { _ in
    }
    .preferredColorScheme(.dark)
}

//
//  LandmarksView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 15/06/26.
//

import SwiftUI

struct LandmarksView: View {
    @ObservedObject var store: LandmarkStore
    @StateObject private var viewModel: LandmarksViewModel

    let isGallery: Bool
    let currentLandmarkIndex: Int
    let onTapBack: () -> Void
    let onUseLandmark: (Int) -> Void
    let onRetakeLandmark: (Int) -> Void

    init(
        store: LandmarkStore,
        isGallery: Bool,
        currentLandmarkIndex: Int,
        onTapBack: @escaping () -> Void,
        onUseLandmark: @escaping (Int) -> Void,
        onRetakeLandmark: @escaping (Int) -> Void
    ) {
        self.store = store
        self.isGallery = isGallery
        self.currentLandmarkIndex = currentLandmarkIndex
        self.onTapBack = onTapBack
        self.onUseLandmark = onUseLandmark
        self.onRetakeLandmark = onRetakeLandmark
        _viewModel = StateObject(
            wrappedValue: LandmarksViewModel(
                store: store,
                isGallery: isGallery
            )
        )
    }

    var body: some View {
        ZStack {
            Color.surfacePrimaryBlack.ignoresSafeArea()

            VStack(spacing: 8) {
                header

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(viewModel.orderedLandmarkIndices.enumerated()), id: \.element) { visualIndex, landmarkIndex in
                            LandmarkImageView(
                                isGallery: isGallery,
                                image: store.capturedLandmarks[landmarkIndex].image,
                                isRetakeNeeded: viewModel.isLandmarkRetakeNeeded(at: landmarkIndex),
                                visualIndex: visualIndex,
                                label: viewModel.landmarkLabel(for: landmarkIndex),
                                currentLandmarkIndex: currentLandmarkIndex,
                                onDelete: {
                                    viewModel.requestDelete(at: landmarkIndex)
                                },
                                onRetake: {
                                    onRetakeLandmark(landmarkIndex)
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.showDetail(for: landmarkIndex, visualIndex: visualIndex)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .sheet(item: $viewModel.selectedDetail) { detail in
            LandmarkDetailSheet(detail: detail) {
                guard detail.selectionState.canUseLandmark else { return }

                viewModel.selectedDetail = nil
                onUseLandmark(detail.landmarkIndex)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert(
            viewModel.deleteRequest?.title ?? "",
            isPresented: Binding(
                get: { viewModel.isDeleteAlertPresented },
                set: viewModel.setDeleteAlertPresented
            )
        ) {
            Button("No", role: .cancel) {
                viewModel.deleteRequest = nil
            }

            Button("Yes", role: .destructive) {
                viewModel.confirmDelete()
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
                Text(viewModel.photoCountText)
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

    private func handleBack() {
        viewModel.handleBack(onTapBack: onTapBack)
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

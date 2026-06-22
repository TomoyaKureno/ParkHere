//
//  LandmarksView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 15/06/26.
//

import SwiftUI

struct LandmarksView: View {
    @ObservedObject var store: LandmarkStore
    @ObservedObject var locationManager: UserLocationManager
    @ObservedObject var altimeterManager: AltimeterManager
    @StateObject private var viewModel: LandmarksViewModel

    let isGallery: Bool
    let currentLandmarkIndex: Int
    let onTapBack: () -> Void
    let onUseLandmark: (Int) -> Void

    init(
        store: LandmarkStore,
        locationManager: UserLocationManager,
        altimeterManager: AltimeterManager,
        isGallery: Bool,
        currentLandmarkIndex: Int,
        onTapBack: @escaping () -> Void,
        onUseLandmark: @escaping (Int) -> Void
    ) {
        self.store = store
        self.locationManager = locationManager
        self.altimeterManager = altimeterManager
        self.isGallery = isGallery
        self.currentLandmarkIndex = currentLandmarkIndex
        self.onTapBack = onTapBack
        self.onUseLandmark = onUseLandmark
        _viewModel = StateObject(
            wrappedValue: LandmarksViewModel(
                store: store,
                locationManager: locationManager,
                altimeterManager: altimeterManager,
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
                                visualIndex: visualIndex,
                                label: viewModel.landmarkLabel(for: landmarkIndex),
                                distanceText: viewModel.distanceText(for: landmarkIndex),
                                floorText: viewModel.floorText(for: landmarkIndex),
                                currentLandmarkIndex: currentLandmarkIndex,
                                onDelete: {
                                    viewModel.requestDelete(at: landmarkIndex)
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
        .sheet(isPresented: $viewModel.isDetailPresented, onDismiss: viewModel.clearDetailSelection) {
            if let initialLandmarkIndex = viewModel.selectedDetailLandmarkIndex {
                LandmarkDetailPagerSheet(
                    viewModel: viewModel,
                    selectedLandmarkIndex: Binding(
                        get: {
                            viewModel.selectedDetailLandmarkIndex ?? initialLandmarkIndex
                        },
                        set: { landmarkIndex in
                            viewModel.selectDetail(at: landmarkIndex)
                        }
                    ),
                    allowsLandmarkSelection: !isGallery,
                    onUseLandmark: { landmarkIndex in
                        viewModel.clearDetailSelection()
                        onUseLandmark(landmarkIndex)
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
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
    let visualIndex: Int
    let label: LandmarkBadgeInfo
    let distanceText: String
    let floorText: String
    let currentLandmarkIndex: Int
    let onDelete: () -> Void

    var isParkingSpot: Bool {
        label.text == "Parking Spot"
    }

    var isSameFloor: Bool {
        floorText == "Same Floor"
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
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                landmarkIndexCircle

                if visualIndex <= currentLandmarkIndex, !isGallery {
                    Capsule()
                        .fill(.clear)
                        .frame(width: 20)
                        .glassEffect(glassEffect, in: Capsule())
                } else if isGallery {
                    Capsule()
                        .fill(.clear)
                        .frame(width: 32, height: 2)
                        .glassEffect(glassEffect, in: Capsule())
                        .padding(.top, 4)
                }
            }

            VStack {
                if visualIndex == currentLandmarkIndex, !isGallery {
                    VStack(alignment: .leading) {
                        Text(isParkingSpot ? "You've Arrived" : "You're now heading to")
                        if !isParkingSpot {
                            Text("Next nearest Landmark")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(isParkingSpot ? .headline : .footnote.weight(.semibold))
                    .frame(height: 40)
                }

                HStack(alignment: .top, spacing: 12) {
                    landmarkImage

                    VStack(alignment: .leading, spacing: 16) {
                        Text(label.text)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(
                                visualIndex <= currentLandmarkIndex && !isGallery
                                    ? Color.surfacePrimaryBlack
                                    : .white
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .allowsTightening(true)
                            .layoutPriority(1)

                        if !isGallery {
                            VStack(spacing: 12) {
                                VStack(spacing: 8) {
                                    Text("est.")

                                    Text(distanceText)
                                        .font(.title2.bold())
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                        .allowsTightening(true)
                                        .layoutPriority(1)
                                }
                                .foregroundStyle(
                                    visualIndex <= currentLandmarkIndex && !isGallery
                                        ? Color(red: 118/255, green: 118/255, blue: 118/255)
                                        : .white.opacity(0.7)
                                )

                                HStack {}
                                    .frame(height: 2)
                                    .frame(maxWidth: .infinity)
                                    .background(.gray)
                                    .clipShape(Capsule())
                                    .padding(.horizontal, 16)

                                VStack(spacing: 8) {
                                    Text(isSameFloor ? "You're on the" : "Go to")

                                    Text(floorText)
                                        .font(.title2.bold())
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                        .allowsTightening(true)
                                        .layoutPriority(1)
                                }
                                .foregroundStyle(Color(red: 241/255, green: 219/255, blue: 0/255))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8)
                .background(
                    visualIndex <= currentLandmarkIndex && !isGallery
                        ? Color.surfaceCardWhiteSmoke
                        : Color.surfaceCardDarkGray
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
        }
        .overlay(alignment: .topTrailing) {
            if isGallery {
                Button(action: onDelete) {
                    Image(systemName: AppIcon.xMark)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(4)
                        .background(.gray)
                        .clipShape(Circle())
                }
                .offset(x: 4, y: -4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var landmarkIndexCircle: some View {
        Text("\(landmarkCircleIndex)")
            .font(.callout.bold())
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .glassEffect(glassEffect, in: Circle())
    }

    private var landmarkImage: some View {
        AdaptiveImageView(
            uiImage: image,
            width: 142,
            height: 224,
            cornerRadius: 16,
            alignment: .center,
            backgroundColor: Color(red: 11/255, green: 11/255, blue: 11/255)
        )
    }
}

private struct LandmarkDetailPagerSheet: View {
    @ObservedObject var viewModel: LandmarksViewModel
    @Binding var selectedLandmarkIndex: Int
    let allowsLandmarkSelection: Bool
    let onUseLandmark: (Int) -> Void

    var body: some View {
        ZStack {
            Color.surfaceSecondaryBlackSmoke.ignoresSafeArea()

            if let detail = viewModel.detail(for: selectedLandmarkIndex) {
                detailPage(detail)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func detailPage(_ detail: LandmarkDetail) -> some View {
        VStack(spacing: 28) {
            Text(detail.progressText)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .padding(.top, 24)

            VStack(spacing: 12) {
                imageCarousel
                    .frame(height: 460)

                pageIndicator
            }

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

            if allowsLandmarkSelection {
                Button {
                    guard detail.selectionState.canUseLandmark else { return }

                    onUseLandmark(detail.landmarkIndex)
                } label: {
                    Text(detail.selectionState.buttonTitle)
                }
                .buttonStyle(.primaryStyle)
                .disabled(!detail.selectionState.canUseLandmark)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }

    private var imageCarousel: some View {
        GeometryReader { proxy in
            let pageSize = proxy.size
            let selectedPage = Binding<Int?> {
                selectedLandmarkIndex
            } set: { landmarkIndex in
                guard let landmarkIndex else { return }

                selectedLandmarkIndex = landmarkIndex
            }

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(viewModel.detailLandmarkIndices, id: \.self) { landmarkIndex in
                        if let detail = viewModel.detail(for: landmarkIndex) {
                            AdaptiveImageView(
                                uiImage: detail.image,
                                width: pageSize.width,
                                height: pageSize.height,
                                cornerRadius: 8
                            )
                            .frame(width: pageSize.width, height: pageSize.height)
                            .clipped()
                            .id(landmarkIndex)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: selectedPage)
            .contentMargins(0, for: .scrollContent)
            .frame(width: pageSize.width, height: pageSize.height)
            .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.detailLandmarkIndices, id: \.self) { landmarkIndex in
                Circle()
                    .fill(
                        landmarkIndex == selectedLandmarkIndex
                            ? Color.white
                            : Color.white.opacity(0.28)
                    )
                    .frame(width: 7, height: 7)
            }
        }
        .frame(height: 12)
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
        locationManager: UserLocationManager(),
        altimeterManager: AltimeterManager(),
        isGallery: false,
        currentLandmarkIndex: 1
    ) {} onUseLandmark: { _ in
    }
    .preferredColorScheme(.dark)
}

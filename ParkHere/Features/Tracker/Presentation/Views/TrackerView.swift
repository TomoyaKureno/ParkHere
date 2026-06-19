//
//  TrackerView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 05/06/26.
//

import CoreLocation
import SwiftUI

struct TrackerView: View {
    @ObservedObject var store: LandmarkStore
    @ObservedObject var locationManager: UserLocationManager
    @ObservedObject var altimeterManager: AltimeterManager
    @StateObject private var viewModel: TrackerViewModel

    let onFoundIt: () -> Void
    let onTapBack: () -> Void
    let onTapLandmarks: (Bool) -> Void

    init(
        store: LandmarkStore,
        locationManager: UserLocationManager,
        altimeterManager: AltimeterManager,
        onFoundIt: @escaping () -> Void,
        onTapBack: @escaping () -> Void,
        onTapLandmarks: @escaping (Bool) -> Void
    ) {
        self.store = store
        self.locationManager = locationManager
        self.altimeterManager = altimeterManager
        self.onFoundIt = onFoundIt
        self.onTapBack = onTapBack
        self.onTapLandmarks = onTapLandmarks
        _viewModel = StateObject(
            wrappedValue: TrackerViewModel(
                store: store,
                locationManager: locationManager,
                altimeterManager: altimeterManager
            )
        )
    }

    var body: some View {
        Group {
            if altimeterManager.isMotionAccessDenied {
                motionAccessDeniedView
            } else {
                trackerContent
            }
        }
        .navigationBarBackButtonHidden()
    }

    private var motionAccessDeniedView: some View {
        ZStack {
            Color.surfacePrimaryBlack
                .ignoresSafeArea()

            VStack {
                UnavailableView.motion
            }
        }
    }

    private var trackerContent: some View {
        GeometryReader { geo in
            let safeWidth = viewModel.safeDimension(geo.size.width)
            let safeHeight = viewModel.safeDimension(geo.size.height)
            let topSafeAreaInset = geo.safeAreaInsets.top
            let bottomSafeAreaInset = viewModel.safeDimension(geo.safeAreaInsets.bottom)
            let overlayHeight = safeHeight * 0.5
            let imageHeight = safeHeight * 0.6
            let indicatorWidth = max(1, (safeWidth / 2) - 1)

            ZStack {
                Color.surfacePrimaryBlack
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    landmarkImage
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: safeWidth,
                            height: imageHeight + bottomSafeAreaInset
                        )
                        .clipped()
                        .offset(y: bottomSafeAreaInset)
                }

                VStack {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.85),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(maxHeight: overlayHeight + topSafeAreaInset)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

                VStack {
                    VStack(spacing: 24) {
                        HStack(spacing: 0) {
                            VStack {
                                Text("est.")

                                HStack(spacing: 8) {
                                    Image(systemName: AppIcon.figureWalk)
                                    Text(viewModel.distanceText)
                                }
                                .font(.title.bold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: indicatorWidth)

                            VStack {}
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                                .background(.gray)
                                .clipShape(Capsule())

                            VStack {
                                Text("est.")

                                floorValueRow
                                    .font(.title.bold())
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: indicatorWidth)
                        }
                        .frame(maxHeight: 64)

                        Text(viewModel.directionGuideText)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)

                        arrowLandmark
                    }
                    .padding(.vertical, 16)

                    Spacer()

                    VStack(spacing: 16) {
                        HStack {
                            VStack(spacing: 8) {
                                Text("You're now heading to")
                                    .font(.headline)

                                Button {
                                    onTapLandmarks(false)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(store.currentTrackingTitle)
                                            .font(.title.bold())
                                        Text(store.currentTrackingProgressText)
                                            .font(.subheadline)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 24)
                                }
                                .glassEffect(.regular, in: Capsule())
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)

                        if viewModel.isTrackingParkingSpot {
                            foundItButton
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if viewModel.isPreparingTrackingLocation || viewModel.trackingLocationFailed {
                    trackingPreparationOverlay
                        .transition(.opacity)
                        .zIndex(10)
                }

                if let rerouteCandidate = viewModel.rerouteCandidate {
                    Color.black.opacity(0.58)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(20)

                    LandmarkReroutePromptView(
                        candidate: rerouteCandidate,
                        onStay: viewModel.dismissRerouteCandidate,
                        onSwitch: viewModel.confirmRerouteCandidate
                    )
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(21)
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .onChange(of: altimeterManager.absoluteAltitude) { _, _ in
            viewModel.updateDisplayedFloorsAndArrival()
        }
        .onChange(of: altimeterManager.relativeAltitude) { _, _ in
            viewModel.updateDisplayedFloorsAndArrival()
        }
        .onReceive(locationManager.$currentLocation) { _ in
            viewModel.evaluateRerouteCandidateIfNeeded()
        }
        .onChange(of: store.trackingTargetIndex) { _, _ in
            viewModel.handleTrackingTargetChanged()
        }
        .onChange(of: viewModel.isInsideArrivalRadius) { _, _ in
            viewModel.handleArrivalRadiusChanged()
        }
        .onChange(of: viewModel.isArrivalConfirmed) { _, newValue in
            viewModel.handleArrivalConfirmationChanged(newValue)
        }
        .onChange(of: viewModel.directionDegree) { _, _ in
            viewModel.handleDirectionChanged()
        }
        .onChange(of: locationManager.heading?.headingAccuracy) { _, _ in
            viewModel.completeInitialTrackingPreparationIfReady()
        }
        .onChange(of: locationManager.needsHeadingCalibration) { _, _ in
            viewModel.completeInitialTrackingPreparationIfReady()
        }
        .alert("Found your car ?", isPresented: $viewModel.showAlert) {
            Button("Not Yet", role: .cancel) {}

            Button("Done") {
                viewModel.finishFoundCar(onFoundIt: onFoundIt)
            }
        } message: {
            Text("This will clear your saved parking spot and landmark photos")
        }
    }

    private var arrowLandmark: some View {
        ZStack(alignment: .top) {
            if viewModel.isShowingRerouteAnimation {
                rerouteAnimationView
            } else if viewModel.isArrivalConfirmed {
                arrivalCheckmarkView
            } else {
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .opacity(viewModel.isInsideForwardInset ? 0 : 1)

                compassArcWithArrow
            }
        }
        .frame(width: 200, height: 200)
        .animation(
            .interpolatingSpring(
                stiffness: 120,
                damping: 12
            ),
            value: viewModel.isArrivalConfirmed
        )
        .animation(
            .interpolatingSpring(
                stiffness: 120,
                damping: 12
            ),
            value: viewModel.isShowingRerouteAnimation
        )
    }

    private var arrivalCheckmarkView: some View {
        Image(systemName: AppIcon.checkmark)
            .font(.system(size: 116).bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.scale.combined(with: .opacity))
    }

    private var rerouteAnimationView: some View {
        Image(systemName: AppIcon.flip)
            .font(.system(size: 116).bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.scale.combined(with: .opacity))
    }

    private var compassArcWithArrow: some View {
        Circle()
            .trim(from: viewModel.arcStart, to: viewModel.arcEnd)
            .stroke(
                .white.opacity(0.8),
                style: StrokeStyle(
                    lineWidth: 16,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
            .scaleEffect(x: viewModel.isArcFlipped ? -1 : 1)
            .opacity(viewModel.shouldHideArc ? 0 : 1)
            .padding(10)
            .overlay {
                directionArrowView
            }
    }

    private var directionArrowView: some View {
        Image(systemName: AppIcon.arrowUp)
            .font(.system(size: 116).bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                compassRotatingDot
            }
            .rotationEffect(.degrees(viewModel.displayedArrowDegree))
    }

    private var compassRotatingDot: some View {
        Circle()
            .fill(viewModel.isInsideForwardInset ? .white : .gray)
            .frame(width: 16, height: 16)
    }

    private var landmarkImage: Image {
        if let currentTrackingImage = store.currentTrackingImage {
            return Image(uiImage: currentTrackingImage)
        }

        return Image("imgLandmark")
    }

    private var floorValueRow: some View {
        HStack(spacing: 8) {
            if viewModel.floorDeltaMeters != nil {
                Image(systemName: viewModel.floorIcon)
                Text(viewModel.floorShortLabel)
            } else {
                Text("--")
            }
        }
    }

    private var foundItButton: some View {
        Button {
            viewModel.showAlert = true
        } label: {
            Text("Found it!")
        }
        .buttonStyle(.primaryStyle)
    }

    @ViewBuilder
    private var trackingPreparationOverlay: some View {
        if viewModel.trackingLocationFailed {
            UnavailableView(
                opacity: 0.96,
                systemImage: AppIcon.locationSlash,
                title: "Current Location Unavailable",
                subtitle: "Turn on location access or move to an area with a better signal to start tracking.",
                buttonTitle: "Back to Home",
                buttonAction: onFoundIt
            )
        } else {
            ZStack {
                Color.surfacePrimaryBlack
                    .opacity(0.96)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)

                    Text("Getting your current location")
                        .font(.title3Bold)
                        .foregroundStyle(.white)

                    Text("Move your iPhone in a figure 8 to calibrate the compass. We’ll start guiding you once your location and compass are ready.")
                        .font(.subheadlineReg)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    @Previewable @StateObject var store = LandmarkStore()
    @Previewable @StateObject var locationManager = UserLocationManager()
    @Previewable @StateObject var altimeterManager = AltimeterManager()

    TrackerView(
        store: store,
        locationManager: locationManager,
        altimeterManager: altimeterManager
    ) {} onTapBack: {} onTapLandmarks: { _ in
    }
    .preferredColorScheme(.dark)
}

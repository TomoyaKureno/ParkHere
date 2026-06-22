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
            let bottomSafeAreaInset = viewModel.safeDimension(geo.safeAreaInsets.bottom)
            let imageHeight = safeHeight * 0.6
            let indicatorWidth = max(1, (safeWidth / 2) - 1)

            ZStack {
                Color.surfacePrimaryBlack
                    .ignoresSafeArea()

                VStack(spacing: 8) {
                    Button {
                        onTapLandmarks(false)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(store.currentTrackingTitle)
                                .font(.title.bold())
                                .foregroundStyle(.white)
                            Text("Nearest landmark from your current location")
                                .font(.footnote.bold())
                                .foregroundStyle(
                                    Color.white.opacity(0.64)
                                )
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )

                        Image(systemName: AppIcon.chevronRight)
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 32)

                    ZStack {
                        if let currentTrackingImage = store.currentTrackingImage {
                            AdaptiveImageView(
                                uiImage: currentTrackingImage,
                                width: safeWidth,
                                height: imageHeight,
                                cornerRadius: 0,
                                alignment: .center,
                                backgroundColor: Color.surfacePrimaryBlack
                            )
                        } else {
                            Image("imgLandmark")
                                .resizable()
                                .scaledToFill()
                                .frame(width: safeWidth, height: imageHeight + bottomSafeAreaInset)
                                .clipped()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .bottomTrailing) {
                        arrowLandmark
                            .padding(16)
                    }

                    VStack(spacing: 16) {
                        Text(viewModel.directionGuideText)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(height: 56)
                            .padding(.horizontal, 16)

                        HStack(spacing: 0) {
                            VStack {
                                Text("est.")

                                TrackerMetricValueRow(
                                    systemImage: AppIcon.figureWalk,
                                    text: viewModel.distanceText
                                )
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: indicatorWidth)

                            VStack {}
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                                .background(.gray)
                                .clipShape(Capsule())

                            VStack {
                                Text(viewModel.displayedFloors == 0 ? "You're on the" : "Go to")

                                TrackerMetricValueRow(
                                    systemImage: viewModel.floorIcon,
                                    text: viewModel.floorDeltaMeters != nil
                                        ? viewModel.floorShortLabel
                                        : "--"
                                )
                            }
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: indicatorWidth)
                        }
                        .frame(minHeight: 64)

                        if viewModel.shouldShowParkingFoundButton {
                            foundItButton
                                .padding(.horizontal, 16)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
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
                    .offset(y: 0)
                    .opacity(viewModel.isInsideForwardInset ? 0 : 1)

                compassArcWithArrow
            }
        }
        .frame(width: 160, height: 160)
        .padding(16)
        .background(.black.opacity(0.6))
        .clipShape(Circle())
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
                .gray.opacity(0.9),
                style: StrokeStyle(
                    lineWidth: 4,
                    lineCap: .round,
                    dash: [7, 11]
                )
            )
            .rotationEffect(.degrees(-90))
            .scaleEffect(x: viewModel.isArcFlipped ? -1 : 1)
            .opacity(viewModel.shouldHideArc ? 0 : 1)
            .padding(8)
            .overlay {
                compassArcArrowHead
            }
            .overlay {
                directionArrowView
            }
    }

    private var compassArcArrowHead: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = max(0, (size / 2) - 10)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let angle = Angle.degrees(Double(viewModel.arcInsetDegree - 90))
            let mirroredX: CGFloat = viewModel.isArcFlipped ? -1 : 1
            let position = CGPoint(
                x: center.x + CGFloat(cos(angle.radians)) * radius * mirroredX,
                y: center.y + CGFloat(sin(angle.radians)) * radius
            )

            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.gray.opacity(0.95))
                .rotationEffect(.degrees(viewModel.isArcFlipped ? 65 : -65))
                .position(position)
        }
        .opacity(viewModel.shouldHideArc ? 0 : 1)
    }

    private var directionArrowView: some View {
        Image(systemName: AppIcon.arrowUp)
            .font(.system(size: 96).bold())
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

    private var foundItButton: some View {
        Button {
            viewModel.showAlert = true
        } label: {
            Text("Parking Found")
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

//
//  CameraView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 01/06/26.
//

import AVFoundation
import CoreLocation
import SwiftUI

struct CameraView: View {
    @ObservedObject var store: LandmarkStore
    @ObservedObject var locationManager: UserLocationManager
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var altimeterManager: AltimeterManager
    let retakeIndex: Int?

    let onDone: () -> Void
    let onPop: () -> Void
    let onTapLandmarks: () -> Void

    private let landmarkResolver = CurrentLandmarkResolver()

    @StateObject private var cameraManager = CameraManager()
    @State private var pinchStartZoom: CGFloat = 1.0
    @State private var isPinching = false
    @State private var showDoneAlert = false
    @State private var didFinishCapture = false
    @State private var isSavingPreviewLandmark = false
    @State private var isOpeningLandmarkGallery = false
    @AppStorage("hasSeenCameraOverlay") private var hasSeenCameraOverlay = false
    @State private var showOverlay = false
    @State private var showDiscardAlert = false
    @AppStorage("hasSeenFirstPhotoAlert") private var hasSeenFirstPhotoAlert = false
    @State private var showFirstPhotoAlert = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if altimeterManager.isMotionAccessDenied {
                VStack { UnavailableView.motion }
            } else {
                takePhotoView
            }

            CameraOverlayView(isPresented: $showOverlay)
        }
        .onAppear {
            isOpeningLandmarkGallery = false
            pinchStartZoom = cameraManager.zoomFactor
            cameraManager.startSession()
            locationManager.requestAccessAndStartUpdating()
            altimeterManager.start()

            if !hasSeenCameraOverlay {
                showOverlay = true
                hasSeenCameraOverlay = true
            }
        }
        .onChange(of: cameraManager.zoomFactor) { _, newValue in
            guard !isPinching else { return }
            pinchStartZoom = newValue
        }
        .onChange(of: cameraManager.cameraState) { _, newValue in
            switch newValue {
            case .takePhoto:
                cameraManager.startSession()
            case .previewPhoto(_, let image, let location):
                saveCapturedLandmark(image: image, location: location)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }

            if case .takePhoto = cameraManager.cameraState {
                cameraManager.startSession()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
            altimeterManager.stop()

            if !didFinishCapture && retakeIndex == nil && !isOpeningLandmarkGallery {
                store.clearParkingSpot()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Ready to save?", isPresented: $showDoneAlert) {
            Button("Review Landmarks", role: .cancel) {
                openLandmarkGallery()
            }

            Button("Save & Finish", role: .none) {
                finishCapture()
            }
        } message: {
            Text("Make sure you've captured all the landmarks you need. You can tap the photo thumbnail to review your landmarks before saving.")
        }
        .alert("Go back to Home?", isPresented: $showDiscardAlert) {
            Button("Stay", role: .cancel) {
                showDiscardAlert = false
            }
            Button("Go Back", role: .destructive) {
                cancelCapture()
            }
        } message: {
            Text("All captured parking spot and landmark photos will be deleted.")
        }
        .alert("Great, you have taken your first photo!", isPresented: $showFirstPhotoAlert) {
            Button("Got it!", role: .cancel) {
                showFirstPhotoAlert = false
                hasSeenFirstPhotoAlert = true
            }
        } message: {
            Text("Add more pictures as you walk further.")
        }
    }

    private var takePhotoView: some View {
        ZStack {
            cameraContent

            VStack {
                headerSection

                Spacer()

                bottomControlsSection
            }
            .ignoresSafeArea(edges: .bottom)

            if cameraManager.shouldShowSettingsButton {
                cameraPermissionUnavailableView
            }
        }
        .gesture(pinchGesture)
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                Button {
                    if store.capturedLandmarks.isEmpty {
                        cancelCapture()
                    } else {
                        showDiscardAlert = true
                    }
                } label: {
                    Image(systemName: AppIcon.chevronLeft)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                }
                .glassEffect(.regular, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(cameraTitle)
                        .font(.title3Bold)

                    Text(cameraSubtitle)
                        .font(.subheadlineReg)
                }
                .foregroundStyle(.white)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation {
                    showOverlay = true
                }
            } label: {
                Image(systemName: AppIcon.questionMarkCircle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.brandPrimaryBlue)
                    .frame(width: 52, height: 52)
            }
            .glassEffect(.regular, in: Circle())
        }
        .padding([.top, .horizontal], 16)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity)
        .background(topGradient)
    }

    private var cameraTitle: String {
        if retakeIndex != nil {
            return "Retake Landmark"
        }

        return store.capturedLandmarks.isEmpty
            ? "Capture Parking Spot"
            : "Capture Landmark \(store.capturedLandmarks.count)"
    }

    private var cameraSubtitle: String {
        if retakeIndex != nil {
            return "Retake this photo to keep your route landmarks complete."
        }

        return store.capturedLandmarks.isEmpty
            ? "Start by capturing photo around your parking spot (car or unique object)"
            : "Capture multiple landmarks to help guide you back to your parking spot"
    }

    private var bottomControlsSection: some View {
        VStack(spacing: 24) {
            zoomAndStatusSection
            captureControlsSection
        }
        .padding(.horizontal)
        .padding(.top, 48)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity)
        .background(bottomGradient)
    }

    private var zoomAndStatusSection: some View {
        VStack(spacing: 12) {
            zoomButtonsSection

            Text(locationManager.statusText)
                .font(.footnote)
                .foregroundStyle(.white)
        }
    }

    private var zoomButtonsSection: some View {
        HStack(spacing: 16) {
            if cameraManager.cameraPosition == .back {
                ForEach(Array(cameraManager.zoomFactors.enumerated()), id: \.offset) { index, zoomFactor in
                    zoomButton(
                        zoomFactor: zoomFactor,
                        zoomMax: index + 1 < cameraManager.zoomFactors.count ? cameraManager.zoomFactors[index + 1] : cameraManager.maxZoomFactor,
                        isLast: index == cameraManager.zoomFactors.count - 1
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            flashButton
        }
    }

    private var flashButton: some View {
        Button {
            cameraManager.cycleFlashMode()
        } label: {
            Image(systemName: cameraManager.flashMode.iconName)
                .font(.footnote)
                .foregroundStyle(cameraManager.flashMode == .off ? .white : .yellow)
                .padding(8)
                .background(.black.opacity(0.25))
                .clipShape(Circle())
        }
        .disabled(!cameraManager.isFlashAvailable)
    }

    private var captureControlsSection: some View {
        HStack {
            thumbnailButton
            Spacer()
            captureButton
            Spacer()
            doneButton
        }
        .padding(.horizontal, 24)
    }

    private var thumbnailButton: some View {
        Button {
            openLandmarkGallery()
        } label: {
            if let lastImage = store.capturedImages.last {
                Image(uiImage: lastImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 56, height: 56)
            }
        }
        .disabled(store.capturedImages.isEmpty || retakeIndex != nil)
    }

    private var captureButton: some View {
        let isBusy = cameraManager.isLoading || locationManager.isRequestingLocation || isSavingPreviewLandmark

        return Button {
            locationManager.requestCurrentLocation { location in
                guard let location else { return }

                cameraManager.takePhoto(location: location) { image, location in
                    saveCapturedLandmark(image: image, location: location)
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 64, height: 64)

                if isBusy {
                    ProgressView()
                        .tint(.black)
                } else if retakeIndex == nil {
                    Text("\(store.capturedLandmarks.count)")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.black)
                }
            }
        }
        .disabled(isBusy)
        .padding(8)
        .overlay {
            Circle().stroke(.white, lineWidth: 4)
        }
    }

    private var doneButton: some View {
        Button {
            showDoneAlert = true
        } label: {
            Text("Save")
        }
        .buttonStyle(PrimaryButtonStyle(width: 80, height: 48))
        .disabled(store.capturedImages.isEmpty || !store.retakeLandmarkIDs.isEmpty || retakeIndex != nil)
    }

    private var topGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.black.opacity(0.5), location: 0.0),
                .init(color: Color.black.opacity(0.45), location: 0.25),
                .init(color: Color.black.opacity(0.0), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var bottomGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.black.opacity(0.5), location: 0.0),
                .init(color: Color.black.opacity(0.45), location: 0.25),
                .init(color: Color.black.opacity(0.0), location: 1.0)
            ]),
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                guard cameraManager.cameraPosition == .back else { return }

                isPinching = true
                let newZoom = pinchStartZoom * value
                cameraManager.setZoomFactor(newZoom)
            }
            .onEnded { _ in
                isPinching = false
                pinchStartZoom = cameraManager.zoomFactor
            }
    }

    private var cameraPermissionUnavailableView: some View {
        UnavailableView(
            opacity: 0.9,
            systemImage: AppIcon.unavailable,
            title: "Camera Access is denied or restricted",
            subtitle: "Camera access is required to take the photo.",
            buttonTitle: "Open Settings"
        )
    }

    private func saveCapturedLandmark(image: UIImage, location: CLLocation?) {
        guard !isSavingPreviewLandmark else { return }

        isSavingPreviewLandmark = true
        let altitude = altimeterManager.currentSample()
        let landmarkID: UUID?

        if let retakeIndex {
            landmarkID = store.replaceLandmark(
                at: retakeIndex,
                image: image,
                location: location,
                landmark: .loading,
                altitude: altitude
            )
            isSavingPreviewLandmark = false
            finishCapture()
        } else {
            landmarkID = store.addLandmark(
                image,
                location: location,
                landmark: .loading,
                altitude: altitude
            )
            cameraManager.cameraState = .takePhoto
            isSavingPreviewLandmark = false

            if !hasSeenFirstPhotoAlert {
                showFirstPhotoAlert = true
            }
        }

        guard let landmarkID else { return }

        let resolver = landmarkResolver
        let landmarkStore = store

        Task { @MainActor in
            let landmark = await resolver.landmark(near: location)
            landmarkStore.updateCapturedLandmark(id: landmarkID, landmark: landmark)
        }
    }

    @ViewBuilder
    private var cameraContent: some View {
        #if targetEnvironment(simulator)
            UnavailableView(
                systemImage: AppIcon.unavailable,
                title: "Camera Access is denied or restricted",
                subtitle: "Camera preview is unavailable in Simulator. Run the app on a real iPhone to use the camera.",
                buttonTitle: "Open Settings"
            )
        #else
            if let errorMessage = cameraManager.errorMessage {
                cameraUnavailableView(message: errorMessage)
            } else {
                CameraPreview(session: cameraManager.session) { devicePoint, _ in
                    cameraManager.focus(at: devicePoint)
                }
                .ignoresSafeArea()
            }
        #endif
    }

    private func cameraUnavailableView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: AppIcon.unavailable)
                .font(.title)
                .foregroundStyle(.yellow)

            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
        }
    }

    func zoomButton(zoomFactor: CGFloat, zoomMax: CGFloat, isLast: Bool) -> some View {
        let currentZoom = roundedZoomFactor(cameraManager.zoomFactor)
        let buttonZoom = roundedZoomFactor(zoomFactor)
        let nextButtonZoom = roundedZoomFactor(zoomMax)
        let isSelected = currentZoom >= buttonZoom
            && (isLast ? currentZoom <= nextButtonZoom : currentZoom < nextButtonZoom)
        let displayed = isSelected ? currentZoom : buttonZoom

        let epsilon = 1e-9
        let isInteger = abs(displayed.truncatingRemainder(dividingBy: 1)) < epsilon

        return (
            Button {
                cameraManager.setZoomFactor(zoomFactor, animated: true)
                pinchStartZoom = zoomFactor
            } label: {
                Text("\(displayed, format: .number.precision(.fractionLength(isInteger ? 0 : 1)))x")
                    .font(.footnote)
                    .foregroundStyle(isSelected ? .yellow : .white)
                    .padding(8)
                    .background(isSelected ? .black.opacity(0.25) : .clear)
                    .clipShape(Circle())
            }
            .disabled(zoomFactor < cameraManager.minZoomFactor || cameraManager.maxZoomFactor < zoomFactor)
        )
    }

    private func roundedZoomFactor(_ factor: CGFloat) -> CGFloat {
        (factor * 10).rounded() / 10
    }

    private func cancelCapture() {
        if retakeIndex == nil {
            store.clearParkingSpot()
        }

        onPop()
    }

    private func finishCapture() {
        didFinishCapture = true
        onDone()
    }

    private func openLandmarkGallery() {
        guard !store.capturedImages.isEmpty else { return }

        showDoneAlert = false
        isOpeningLandmarkGallery = true
        onTapLandmarks()
    }
}

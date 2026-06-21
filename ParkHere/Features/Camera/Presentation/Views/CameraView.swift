//
//  CameraView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 01/06/26.
//

import AVFoundation
import SwiftUI

struct CameraView: View {
    @ObservedObject var store: LandmarkStore
    @ObservedObject var locationManager: UserLocationManager
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var altimeterManager: AltimeterManager
    @StateObject private var viewModel: CameraViewModel

    let onDone: () -> Void
    let onPop: () -> Void
    let onTapLandmarks: () -> Void

    @StateObject private var cameraManager = CameraManager()
    @State private var pinchStartZoom: CGFloat = 1.0
    @State private var isPinching = false
    @AppStorage("hasSeenCameraOverlay") private var hasSeenCameraOverlay = false
    @AppStorage("hasSeenFirstPhotoAlert") private var hasSeenFirstPhotoAlert = false
    @State private var showTipsSheet = false
    @State private var isShowingFlash = false

    init(
        store: LandmarkStore,
        locationManager: UserLocationManager,
        altimeterManager: AltimeterManager,
        onDone: @escaping () -> Void,
        onPop: @escaping () -> Void,
        onTapLandmarks: @escaping () -> Void
    ) {
        self.store = store
        self.locationManager = locationManager
        self.altimeterManager = altimeterManager
        self.onDone = onDone
        self.onPop = onPop
        self.onTapLandmarks = onTapLandmarks
        _viewModel = StateObject(
            wrappedValue: CameraViewModel(
                store: store,
                locationManager: locationManager,
                altimeterManager: altimeterManager
            )
        )
    }

    var body: some View {
        ZStack {
            Color.surfacePrimaryBlack
                .ignoresSafeArea()

            if altimeterManager.isMotionAccessDenied {
                VStack { UnavailableView.motion }
            } else {
                takePhotoView
            }

            CameraOverlayView(isPresented: $viewModel.showOverlay)

            LandmarksOverlayView(isPresented: $viewModel.showLandmarksOverlay)
        }
        .onAppear {
            pinchStartZoom = cameraManager.zoomFactor
            viewModel.onAppear()

            if !hasSeenCameraOverlay {
                viewModel.showOverlay = true
                hasSeenCameraOverlay = true
            } else {
                viewModel.startCaptureSession(cameraManager: cameraManager)
            }
        }
        .onChange(of: viewModel.showOverlay) { oldValue, newValue in
            if oldValue == true && newValue == false {
                viewModel.startCaptureSession(cameraManager: cameraManager)
            }
        }
        .onChange(of: cameraManager.zoomFactor) { _, newValue in
            guard !isPinching else { return }
            pinchStartZoom = newValue
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }

            viewModel.onScenePhaseActive(cameraManager: cameraManager)
        }
        .onDisappear {
            viewModel.onDisappear(cameraManager: cameraManager)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Ready to save?", isPresented: $viewModel.showDoneAlert) {
            Button("Review Landmarks", role: .cancel) {
                viewModel.openLandmarkGallery(onTapLandmarks: onTapLandmarks)
            }

            Button("Save & Finish", role: .none) {
                viewModel.finishCapture(onDone: onDone)
            }
        } message: {
            Text("Make sure you've captured all the landmarks you need. You can tap the photo thumbnail to review your landmarks before saving.")
        }
        .alert("Go back to Home?", isPresented: $viewModel.showDiscardAlert) {
            Button("Stay", role: .cancel) {
                viewModel.showDiscardAlert = false
            }
            Button("Go Back", role: .destructive) {
                viewModel.cancelCapture(onPop: onPop)
            }
        } message: {
            Text("All captured parking spot and landmark photos will be deleted.")
        }
        .alert("Great, you have taken your first photo!", isPresented: $viewModel.showFirstPhotoAlert) {
            Button("Got it!", role: .cancel) {
                viewModel.dismissFirstPhotoAlert()
                hasSeenFirstPhotoAlert = true
            }
        } message: {
            Text("Add more pictures as you walk further.")
        }
        .sheet(isPresented: $showTipsSheet) {
            TipsSheetView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var takePhotoView: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top
            
            ZStack {
                cameraContent

                if isShowingFlash {
                    Color.black
                        .ignoresSafeArea()
                }

                VStack {
                    headerSection(topInset: topInset)

                    Spacer()

                    bottomControlsSection
                }
                .ignoresSafeArea()

                if cameraManager.shouldShowSettingsButton {
                    cameraPermissionUnavailableView
                }
            }
            .gesture(pinchGesture)
        }
    }

    private func headerSection(topInset: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                Button {
                    viewModel.handleBack(onPop: onPop)
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
                showTipsSheet = true
            } label: {
                Image(systemName: AppIcon.questionMarkCircle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.brandPrimaryBlue)
                    .frame(width: 52, height: 52)
            }
            .glassEffect(.regular, in: Circle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 16 + topInset)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity)
        .background(topGradient)
    }

    private var cameraTitle: String {
        viewModel.cameraTitle
    }

    private var cameraSubtitle: String {
        viewModel.cameraSubtitle
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

            Text(cameraLocationStatusText)
                .font(.footnote)
                .foregroundStyle(.white)
        }
    }

    private var cameraLocationStatusText: String {
        viewModel.cameraLocationStatusText
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
        HStack(spacing: 0) {
            thumbnailButton
                .frame(maxWidth: .infinity, alignment: .center)

            captureButton
                .frame(maxWidth: .infinity, alignment: .center)

            doneButton
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    private var thumbnailButton: some View {
        Button {
            openLandmarkGallery()
        } label: {
            if let lastImage = store.capturedLandmarks.last?.image {
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
        .disabled(viewModel.isThumbnailDisabled)
    }

    private var captureButton: some View {
        let isBusy = cameraManager.isLoading || viewModel.isSavingPreviewLandmark
        let isCaptureUnavailable = viewModel.currentCaptureLocation == nil

        return Button {
            isShowingFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.15)) {
                    isShowingFlash = false
                }
            }

            viewModel.capturePhoto(
                using: cameraManager,
                shouldShowFirstPhotoAlert: !hasSeenFirstPhotoAlert
            )
        } label: {
            ZStack {
                Circle()
                    .fill(isCaptureUnavailable ? .white.opacity(0.35) : .white)
                    .frame(width: 64, height: 64)

                if isBusy {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("\(store.capturedLandmarks.count)")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.black)
                }
            }
        }
        .disabled(isBusy || isCaptureUnavailable)
        .padding(8)
        .overlay {
            Circle().stroke(isCaptureUnavailable ? .white.opacity(0.35) : .white, lineWidth: 4)
        }
    }

    private var doneButton: some View {
        Button {
            viewModel.requestDoneAlert()
        } label: {
            Text("Save")
        }
        .buttonStyle(PrimaryButtonStyle(width: 80, height: 48))
        .disabled(viewModel.isDoneDisabled)
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

    private func openLandmarkGallery() {
        viewModel.openLandmarkGallery(onTapLandmarks: onTapLandmarks)
    }
}

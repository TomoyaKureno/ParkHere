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
    @ObservedObject var store: WaypointStore
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
    @State private var isSavingPreviewWaypoint = false
    @State private var isOpeningLandmarkGallery = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if altimeterManager.isMotionAccessDenied {
                VStack { UnavailableView.motion }
            } else if case .takePhoto = cameraManager.cameraState {
                takePhotoView
            } else if case .previewPhoto(_, let image, let location) = cameraManager.cameraState {
                previewPhotoView(image: image, location: location)
            }
        }
        .onAppear {
            isOpeningLandmarkGallery = false
            pinchStartZoom = cameraManager.zoomFactor
            cameraManager.startSession()
            locationManager.requestAccessAndStartUpdating()
            altimeterManager.start()
        }
        .onChange(of: cameraManager.zoomFactor) { _, newValue in
            guard !isPinching else { return }
            pinchStartZoom = newValue
        }
        .onChange(of: cameraManager.cameraState) { _, newValue in
            switch newValue {
            case .takePhoto:
                cameraManager.startSession()
            case .previewPhoto:
                cameraManager.stopSession()
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
            Button("Review Waypoints", role: .cancel) {
                openLandmarkGallery()
            }
                
            Button("Save & Finish", role: .none) {
                finishCapture()
            }
        } message: {
            Text("Make sure you've captured all the landmarks you need. You can tap the photo thumbnail to review your waypoints before saving.")
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
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                Color.clear
                    .frame(width: 56, height: 56)
            }
        }
        .disabled(store.capturedImages.isEmpty)
    }
    
    private var captureButton: some View {
        let isBusy = cameraManager.isLoading || locationManager.isRequestingLocation
        
            return Button {
                locationManager.requestCurrentLocation { location in
                    guard let location else { return }

                    cameraManager.takePhoto(location: location)
                }
            } label: {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 64, height: 64)
                
                if isBusy {
                    ProgressView()
                        .tint(.black)
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
            Image(systemName: AppIcon.checkmark)
                .bold()
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .glassEffect(.regular)
        }
        .disabled(store.capturedImages.isEmpty || !store.retakeWaypointIDs.isEmpty)
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
    
    private func previewPhotoView(image: UIImage, location: CLLocation?) -> some View {
        GeometryReader { proxy in
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .ignoresSafeArea()
                .overlay(alignment: .bottom) {
                    HStack {
                        Button {
                            guard !isSavingPreviewWaypoint else { return }

                            cameraManager.cameraState = .takePhoto
                        } label: {
                            Image(systemName: AppIcon.xMark)
                                .bold()
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .glassEffect(.regular)
                        }
                        
                        Spacer()
                        Spacer()

                        Button {
                            savePreviewWaypoint(image: image, location: location)
                        } label: {
                            ZStack {
                                Image(systemName: AppIcon.checkmark)
                                    .bold()
                                    .foregroundStyle(.white)
                                    .opacity(isSavingPreviewWaypoint ? 0 : 1)

                                if isSavingPreviewWaypoint {
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                            .frame(width: 56, height: 56)
                            .glassEffect(.regular)
                        }
                        .disabled(isSavingPreviewWaypoint)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
        }
        .ignoresSafeArea()
    }

    private func savePreviewWaypoint(image: UIImage, location: CLLocation?) {
        guard !isSavingPreviewWaypoint else { return }

        isSavingPreviewWaypoint = true

        Task { @MainActor in
            let landmark = await landmarkResolver.landmark(near: location)
            if let retakeIndex {
                store.replaceWaypoint(
                    at: retakeIndex,
                    image: image,
                    location: location,
                    landmark: landmark,
                    altitude: altimeterManager.currentSample()
                )
                finishCapture()
            } else {
                store.addWaypoint(
                    image,
                    location: location,
                    landmark: landmark,
                    altitude: altimeterManager.currentSample()
                )
                cameraManager.cameraState = .takePhoto
            }
            isSavingPreviewWaypoint = false
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
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        #else
            CameraPreview(session: cameraManager.session) { devicePoint, _ in
                cameraManager.focus(at: devicePoint)
            }
            .ignoresSafeArea()
        #endif
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                Button {
                    cancelCapture()
                } label: {
                    Image(systemName: AppIcon.chevronLeft)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular, in: Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capture Waypoint")
                        .font(.title3Bold)
                    
                    Text("Capture multiple landmarks to help guide you back to your parking spot")
                        .font(.subheadlineReg)
                }
                .foregroundStyle(.white)
            }
            
            Spacer(minLength: 0)
            
            Image(systemName: AppIcon.mapPin)
                .font(.titleBold)
                .foregroundStyle(.blue)
        }
        .padding([.top, .horizontal], 16)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.black.opacity(0.5), location: 0.0),
                    .init(color: Color.black.opacity(0.45), location: 0.25),
                    .init(color: Color.black.opacity(0.0), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
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

//
//  CameraView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 01/06/26.
//

import AVFoundation
import SwiftUI

struct CameraView: View {
    @ObservedObject var store: WaypointStore
    @ObservedObject var locationManager: UserLocationManager
    @ObservedObject var altimeterManager: AltimeterManager

    let onDone: () -> Void
    let onPop: () -> Void

    @StateObject private var cameraManager = CameraManager()
    @State private var pinchStartZoom: CGFloat = 1.0
    @State private var isPinching = false
    @State private var isWaypointSheetPresented = false
    @State private var showDoneAlert = false
    @State private var didFinishCapture = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if altimeterManager.isMotionAccessDenied {
                VStack { UnavailableView.motion }
            } else {
                if case .takePhoto = cameraManager.cameraState {
                    cameraContent

                    VStack {
                        HStack(alignment: .top, spacing: 8) {
                            HStack(alignment: .top, spacing: 16) {
                                Button {
                                    cancelCapture()
                                } label: {
                                    Image(systemName: AppIcon.chevronLeft)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 52, height: 52)
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

                        Spacer()

                        VStack(spacing: 24) {
                            VStack(spacing: 12) {
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

                                Text(locationManager.statusText)
                                    .font(.footnote)
                                    .foregroundStyle(.white)
                            }

                            HStack {
                                Button {
                                    isWaypointSheetPresented = true
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

                                Spacer()

                                Button {
                                    locationManager.requestCurrentLocation { location in
                                        guard let location else { return }
                                        
                                        let altitude = altimeterManager.currentSample()
                                        store.saveParkingLocation(location, altitude: altitude)

                                        cameraManager.takePhoto(location: location)
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 64, height: 64)

                                        if cameraManager.isLoading || locationManager.isRequestingLocation {
                                            ProgressView()
                                                .tint(.black)
                                        }
                                    }
                                }
                                .disabled(cameraManager.isLoading || locationManager.isRequestingLocation)
                                .padding(8)
                                .overlay {
                                    Circle().stroke(.white, lineWidth: 4)
                                }

                                Spacer()

                                Button {
                                    showDoneAlert = true
                                } label: {
                                    Image(systemName: AppIcon.checkmark)
                                        .bold()
                                        .foregroundStyle(.white)
                                        .frame(width: 56, height: 56)
                                        .glassEffect(.regular)
                                }
                                .disabled(store.capturedImages.isEmpty)
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.horizontal)
                        .padding(.top, 48)
                        .padding(.bottom, 40)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.black.opacity(0.5), location: 0.0),
                                    .init(color: Color.black.opacity(0.45), location: 0.25),
                                    .init(color: Color.black.opacity(0.0), location: 1.0)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    }
                    .ignoresSafeArea(edges: .bottom)
                } else if case .previewPhoto(_, let image, let location) = cameraManager.cameraState {
                    Image(uiImage: image)
                        .resizable()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()

                    HStack {
                        Button {
                            cameraManager.cameraState = .takePhoto
                        } label: {
                            Image(systemName: AppIcon.xMark)
                                .bold()
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .glassEffect(.regular)
                        }

                        Spacer()

                        Button {
                            store.addWaypoint(image, location: location)
                            cameraManager.cameraState = .takePhoto
                        } label: {
                            Image(systemName: AppIcon.checkmark)
                                .bold()
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .glassEffect(.regular)
                        }
                    }
                    .padding(.horizontal, 24)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
        .onAppear {
            pinchStartZoom = cameraManager.zoomFactor
            cameraManager.startSession()
            locationManager.requestAccessAndStartUpdating()
            altimeterManager.start()
        }
        .onChange(of: cameraManager.zoomFactor) { _, newValue in
            guard !isPinching else { return }
            pinchStartZoom = newValue
        }
        .onDisappear {
            cameraManager.stopSession()

            if !didFinishCapture {
                store.clearParkingSpot()
            }
        }
        .gesture(
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
        )
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Ready to save?", isPresented: $showDoneAlert) {
            Button("Review Waypoints", role: .cancel) {
                showDoneAlert = false
                isWaypointSheetPresented = true
            }

            Button("Save & Finish", role: .none) {
                finishCapture()
            }
        } message: {
            Text("Make sure you've captured all the landmarks you need. You can tap the photo thumbnail to review your waypoints before saving.")
        }
        .sheet(isPresented: $isWaypointSheetPresented) {
            WaypointSheet(
                onSaveParkingSpot: {
                    isWaypointSheetPresented = false
                    finishCapture()
                }
            )
            .environmentObject(store)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var cameraContent: some View {
        #if targetEnvironment(simulator)
        cameraUnavailableView(
            message: "Camera preview is unavailable in Simulator. Run the app on a real iPhone to use the camera."
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
        store.clearParkingSpot()
        onPop()
    }

    private func finishCapture() {
        didFinishCapture = true
        onDone()
    }
}

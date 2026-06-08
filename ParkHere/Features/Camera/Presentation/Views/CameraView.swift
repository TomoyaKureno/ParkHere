//
//  CameraView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 01/06/26.
//

import AVFoundation
import SwiftUI

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var waypointStore = WaypointStore() //nb: environment object is used when a view needs access to an object created somewhere above it

    let onDone: () -> Void

    @StateObject private var cameraManager = CameraManager()
    @State private var pinchStartZoom: CGFloat = 1.0
    @State private var isPinching = false
    @State private var isWaypointSheetPresented = false
    @State private var showDoneAlert = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            cameraContent

            VStack {
                HStack {
                    HStack(spacing: 16) {
                        Image(systemName: AppIcon.mapPin)
                            .font(.title2.bold())
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text("Capture Waypoint")
                                .font(.title2.bold())

                            Text("Capture multiple landmarks to help guide you back to your parking spot")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.white)
                    }

                    Spacer(minLength: 32)

                    Button {} label: {
                        Image(systemName: AppIcon.questionMark)
                            .font(.subheadline.bold())
                            .padding(8)
                            .overlay(
                                Circle().stroke(.blue, lineWidth: 2)
                            )
                            .padding(8)
                            .background(
                                Color(red: 27/255, green: 31/255, blue: 38/255, opacity: 1.0)
                            )
                            .clipShape(Circle())
                    }
                }
                .padding([.top, .horizontal])
                .padding(.bottom, 40)
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

                        Text("Location data saves automatically")
                            .font(.footnote)
                            .foregroundStyle(.white)
                    }

                    HStack {
                        Button {
                            isWaypointSheetPresented = true
                        } label: {
                            if let lastImage = waypointStore.capturedImages.last {
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
                        .disabled(waypointStore.capturedImages.isEmpty)

                        Spacer()

                        Button {
                            cameraManager.takePhoto()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 64, height: 64)

                                if cameraManager.isLoading {
                                    ProgressView()
                                        .tint(.black)
                                }
                            }
                        }
                        .disabled(cameraManager.isLoading)
                        .padding(8)
                        .overlay {
                            Circle().stroke(.white, lineWidth: 4)
                        }

                        Spacer()
                                                
                        Button{
                            showDoneAlert = true
                        } label: {
                            Image(systemName: AppIcon.checkmark)
                                .bold()
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .glassEffect(.regular)
                        }
                        .disabled(waypointStore.capturedImages.isEmpty)

//                        Button {
//                            cameraManager.switchCamera()
//                        } label: {
//                            Image(systemName: AppIcon.flip)
//                                .bold()
//                                .foregroundStyle(.white)
//                                .frame(width: 56, height: 56)
//                                .glassEffect(.regular)
//                        }
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
        }
        .onAppear {
            pinchStartZoom = cameraManager.zoomFactor
            cameraManager.startSession()
        }
        .onChange(of: cameraManager.zoomFactor) { _, newValue in
            guard !isPinching else { return }
            pinchStartZoom = newValue
        }
        .onChange(of: cameraManager.cameraState) { _, newValue in
            if case .previewPhoto(let image) = newValue {
                waypointStore.addWaypoint(image)
                cameraManager.cameraState = .takePhoto
            }
        }
        .onDisappear {
            cameraManager.stopSession()
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
            }
            Button("Save & Finish", role: .none) {
                onDone()
            }
        } message: {
            Text("Make sure you've captured all the landmarks you need. You can tap the photo thumbnail to review your waypoints before saving.")
        }
        .sheet(isPresented: $isWaypointSheetPresented) {
            WaypointSheet(
                onSaveParkingSpot: {
                    isWaypointSheetPresented = false
                    onDone()
                }
            )
            .environmentObject(waypointStore)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)        }
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
        (factor * 10).rounded()/10
    }
}

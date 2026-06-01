//
//  CameraView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 01/06/26.
//

import SwiftUI

struct CameraView: View {
    @StateObject var cameraManager = CameraManager()
    @State private var pinchStartZoom: CGFloat = 1.0
    
    private var zoomFactors = [1.0, 2.0, 5.0]
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newZoom = pinchStartZoom * value
                            cameraManager.setZoomFactor(newZoom)
                        }
                        .onEnded { _ in
                            pinchStartZoom = cameraManager.zoomFactor
                        }
                )
                .onAppear {
                    pinchStartZoom = cameraManager.zoomFactor
                    cameraManager.startSession()
                }
                .onDisappear {
                    cameraManager.stopSession()
                }
            
            VStack {
                HStack {
                    HStack(spacing: 16) {
                        Image(systemName: "car.fill")
                            .font(.title2.bold())
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text("Capture Parking Spot")
                                .font(.title2.bold())
                                
                            Text("Snap the nearest pillar, zone sign, or elevator.")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.white)
                    }
                    
                    Spacer(minLength: 32)
                    
                    Button {} label: {
                        Image(systemName: "questionmark")
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
                            ForEach(zoomFactors, id: \.self) { zoomFactor in
                                zoomButton(zoomFactor: zoomFactor)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .topTrailing) {
                            Button {
                                cameraManager.cycleFlashMode()
                            } label: {
                                Image(systemName: cameraManager.flashMode.iconName)
                                    .font(.footnote)
                                    .foregroundStyle(.yellow)
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
                    
                    Button {
                        cameraManager.takePhoto()
                    } label: {
                        Circle()
                            .fill(.white)
                            .frame(width: 64, height: 64)
                    }
                    .padding(8)
                    .overlay {
                        Circle().stroke(.white, lineWidth: 4)
                    }
                    
                    HStack {
                        Button {} label: {
                            Image(systemName: "xmark")
                                .bold()
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .glassEffect(.regular)
                        }

                        Spacer()

                        Button {
                            cameraManager.switchCamera()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .bold()
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .glassEffect(.regular)
                        }
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
    }
    
    func zoomButton(zoomFactor: Double) -> some View {
        Button {
            cameraManager.setZoomFactor(zoomFactor, animated: true)
        } label: {
            Text("1x")
                .font(.footnote)
                .foregroundStyle(cameraManager.zoomFactor == zoomFactor ? .yellow : .white)
                .padding(8)
                .background(cameraManager.zoomFactor == zoomFactor ? .black.opacity(0.25) : .clear)
                .clipShape(Circle())
        }
        .disabled(cameraManager.maxZoomFactor < zoomFactor)
    }
}

#Preview {
    CameraView()
}

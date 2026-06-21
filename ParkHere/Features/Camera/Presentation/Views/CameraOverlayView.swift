//
//  OnboardingOverlayView.swift
//  ParkHere
//
//  Created by Kelly Angeline on 15/06/26.
//

import SwiftUI

struct CameraOverlayView: View {
    @Binding var isPresented: Bool
    @State private var overlayIndex = 0
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.surfacePrimaryBlackTransparent
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = true
                    }
                
                VStack(spacing:24) {
                    if overlayIndex == 0 {
                        Image("CameraOverlay1")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 180)
                            .padding(.top, 16)
                        
                        VStack(spacing: 8) {
                            Text("Capture your Parking Spot")
                                .font(.title3Bold)
                                .foregroundStyle(.white)
                            
                            Text("The picture will be used later to help you find your vehicle.")
                                .font(.subheadlineReg)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        
                        // Dot view control
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.white)
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                        
                        Button {
                            withAnimation {
                                overlayIndex = 1
                            }
                        } label: {
                            Text("Next")
                        }
                        .buttonStyle(PrimaryButtonStyle(width: 280, height: 50))
                    } else {
                        Image("CameraOverlay2")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 180)
                            .padding(.top, 16)
                        
                        VStack(spacing: 8) {
                            Text("Add Landmarks Along Your Route")
                                .font(.title3Bold)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Take photos of signs, pillars, or cues until the entrance so you can easily find your car later.")
                                .font(.subheadlineReg)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        
                        // Dots indicator
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(.white)
                                .frame(width: 8, height: 8)
                        }
                        
                        Button {
                            withAnimation {
                                isPresented = false
                                overlayIndex = 0
                            }
                        } label: {
                            Text("Start Capturing")
                        }
                        .buttonStyle(PrimaryButtonStyle(width: 280, height:50))
                    }
                }
                .padding(20)
                .background(Color.surfaceSecondaryBlackSmoke)
                .cornerRadius(28)
                .padding(.horizontal, 32)
                .shadow(radius: 20)
            }
            .transition(.opacity)
        }
    }
}

#Preview {
    CameraOverlayView(isPresented: .constant(true))
        .preferredColorScheme(.dark)
}

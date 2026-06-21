//
//  OnboardingOverlayView.swift
//  ParkHere
//
//  Created by Kelly Angeline on 15/06/26.
//

import SwiftUI

struct CameraOverlayView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image("CameraOverlay1")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                        .padding(.top, 16)
                    
                    VStack(spacing: 8) {
                        Text("Capture your Parking Spot")
                            .font(.title3Bold)
                            .foregroundStyle(Color.surfaceSecondaryWhite)
                        
                        Text("The picture will be used later to help you find your vehicle.")
                            .font(.subheadlineReg)
                            .foregroundStyle(Color.surfaceSecondaryWhite.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    
                    Button {
                        withAnimation {
                            isPresented = false
                        }
                    } label: {
                        Text("Okay")
                    }
                    .buttonStyle(PrimaryButtonStyle(width: 280, height: 50))
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

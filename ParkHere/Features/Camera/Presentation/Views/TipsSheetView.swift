//
//  TipsSheetView.swift
//  ParkHere
//
//  Created by Antigravity on 20/06/26.
//

import SwiftUI

struct TipsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.surfacePrimaryBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                Text("Tips")
                    .font(.titleBold)
                    .foregroundStyle(Color.surfaceSecondaryWhite)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Section 1: Capture Your Parking Spot
                        VStack(spacing: 16) {
                            Image("CameraOverlay1")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 160)
                            
                            VStack(spacing: 8) {
                                Text("Capture Your Parking Spot")
                                    .font(.title3Bold)
                                    .foregroundStyle(Color.surfaceSecondaryWhite)
                                    .multilineTextAlignment(.center)
                                
                                Text("The picture will be used later to help you find your car")
                                    .font(.subheadlineReg)
                                    .foregroundStyle(Color.surfaceSecondaryWhite.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                        
                        Divider()
                            .background(Color.surfaceSecondaryWhite.opacity(0.15))
                            .padding(.horizontal, 16)
                        
                        // Section 2: Add Landmarks Along Your Route
                        VStack(spacing: 16) {
                            Image("CameraOverlay2")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 160)
                            
                            VStack(spacing: 8) {
                                Text("Add Landmarks Along Your Route")
                                    .font(.title3Bold)
                                    .foregroundStyle(Color.surfaceSecondaryWhite)
                                    .multilineTextAlignment(.center)
                                
                                Text("Take photos of signs, pillars, or cues until the entrance so you can easily find your car later.")
                                    .font(.subheadlineReg)
                                    .foregroundStyle(Color.surfaceSecondaryWhite.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                        
                        Divider()
                            .background(Color.surfaceSecondaryWhite.opacity(0.15))
                            .padding(.horizontal, 16)
                        
                        // Section 3: Good to Capture
                        VStack(spacing: 16) {
                            // 2x2 grid
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image("Overlay1")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .cornerRadius(8)
                                    Image("Overlay2")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .cornerRadius(8)
                                }
                                HStack(spacing: 8) {
                                    Image("Overlay3")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .cornerRadius(8)
                                    Image("Overlay4")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 32)
                            
                            VStack(spacing: 8) {
                                Text("Good to Capture")
                                    .font(.title3Bold)
                                    .foregroundStyle(Color.surfaceSecondaryWhite)
                                    .multilineTextAlignment(.center)
                                
                                Text("Focus on noticeable things that stand out so you can quickly recognize them when returning")
                                    .font(.subheadlineReg)
                                    .foregroundStyle(Color.surfaceSecondaryWhite.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

#Preview {
    TipsSheetView()
        .preferredColorScheme(.dark)
}

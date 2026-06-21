//
//  LandmarksOverlayView.swift
//  ParkHere
//
//  Created by Antigravity on 20/06/26.
//

import SwiftUI

struct LandmarksOverlayView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TabView(selection: $currentPage) {
                        // Page 1
                        VStack(spacing: 24) {
                            Image("CameraOverlay2")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 180)
                                .padding(.top, 16)
                            
                            VStack(spacing: 8) {
                                Text("Add Landmarks Along Your Route")
                                    .font(.title3Bold)
                                    .foregroundStyle(Color.surfaceSecondaryWhite)
                                    .multilineTextAlignment(.center)
                                
                                Text("Take photos of signs, pillars, or cues until the entrance so you can easily find your car later.")
                                    .font(.subheadlineReg)
                                    .foregroundStyle(Color.surfaceSecondaryWhite.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .tag(0)
                        
                        // Page 2
                        VStack(spacing: 24) {
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
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            
                            VStack(spacing: 8) {
                                Text("Good to Capture")
                                    .font(.title3Bold)
                                    .foregroundStyle(Color.surfaceSecondaryWhite)
                                    .multilineTextAlignment(.center)
                                
                                Text("Focus on noticeable things that stand out so you can quickly recognize them when returning")
                                    .font(.subheadlineReg)
                                    .foregroundStyle(Color.surfaceSecondaryWhite.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 340)
                    
                    // Dots indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(currentPage == 0 ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(currentPage == 1 ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    // Button only on Page 2 (currentPage == 1)
                    if currentPage == 1 {
                        Button {
                            withAnimation {
                                isPresented = false
                            }
                        } label: {
                            Text("Start Capturing")
                        }
                        .buttonStyle(PrimaryButtonStyle(width: 280, height: 50))
                        .transition(.opacity)
                    } else {
                        // Empty placeholder to maintain height
                        Spacer()
                            .frame(height: 50)
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
    LandmarksOverlayView(isPresented: .constant(true))
        .preferredColorScheme(.dark)
}

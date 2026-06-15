import SwiftUI

struct LandmarkOnboardingOverlay: View {
    @Binding var isPresented: Bool
    @State private var onboardingPage = 0

    var body: some View {
        if isPresented {
            ZStack {
                // Dimmed background
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                // Onboarding Card Dialog
                VStack(spacing: 24) {
                    if onboardingPage == 0 {
                        // Page 1: Capture your Parking Spot
                        Image("LandmarkImg1")
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
                        
                        // Dots indicator
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
                                onboardingPage = 1
                            }
                        } label: {
                            Text("Next")
                        }
                        .buttonStyle(PrimaryButtonStyle(width: 280, height: 50))
                        
                    } else {
                        // Page 2: Add Landmarks Along Your Route
                        Image("LandmarkImg2")
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
                            }
                        } label: {
                            Text("Start Capturing")
                        }
                        .buttonStyle(PrimaryButtonStyle(width: 280, height: 50))
                    }
                }
                .padding(24)
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
    LandmarkOnboardingOverlay(isPresented: .constant(true))
        .preferredColorScheme(.dark)
}

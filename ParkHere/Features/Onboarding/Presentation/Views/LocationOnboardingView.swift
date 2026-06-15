import SwiftUI

struct LocationOnboardingView: View {
    @Binding var isPresented: Bool
    let onEnableLocation: () -> Void
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0, green: 0, blue: 0), location: 0.0),
                    .init(color: Color(red: 1/255, green: 27/255, blue: 46/255), location: 0.3),
                    .init(color: .clear, location: 0.75)
                ],
                startPoint: .bottom,
                endPoint: .top
            )            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Car & Parking Sign Asset
                Image("CarImg")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 24)
                
                Spacer()
                
                // Texts Section
                VStack(spacing: 16) {
                    Text("Location Needed")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("We help you save your parking spot with images, GPS coordinates, and elevation.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 120)
                
                // Enable Button
                Button {
                    onEnableLocation()
                    withAnimation {
                        isPresented = false
                    }
                } label: {
                    Text("Enable Location")
                }
                .buttonStyle(PrimaryButtonStyle(width: 280, height: 52))
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    LocationOnboardingView(isPresented: .constant(true), onEnableLocation: {})
}

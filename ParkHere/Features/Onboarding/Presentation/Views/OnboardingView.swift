//
//  OnboardingView.swift
//  ParkHere
//
//  Created by Kelly Angeline on 09/06/26.
//

import SwiftUI

struct OnboardingView: View {
    let onLearnMore: () -> Void

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            Image("OnboardingImg0")
                .resizable()
                .frame(width:282, height: 615)
                .ignoresSafeArea()

            LinearGradient(
                stops: [
                    .init(color: Color(red: 0, green: 0, blue: 0), location: 0.0),
                    .init(color: Color(red: 1/255, green: 27/255, blue: 46/255), location: 0.3),
                    .init(color: .clear, location: 0.75)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                HStack(spacing: 100) {                    Image("OnboardingImg1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 117, height: 290)   .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
                    Image("OnboardingImg2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 127, height: 272)
                        .padding(.top,100)
                        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
                }
                
                VStack(spacing: 12) {
                    Text("Never Forget\nWhere you Parked")
                        .font(.titleBold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text("We help you save your parking spot with images, GPS coordinates, and elevation.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.top, 15)
                        .padding(.horizontal, 40)
                }
                Spacer()
                
                Button(action: onLearnMore) {
                    Text("Learn More")
                }
                .buttonStyle(.primaryStyle)
                }
        }
    }
}

#Preview {
    OnboardingView(onLearnMore: {})
}

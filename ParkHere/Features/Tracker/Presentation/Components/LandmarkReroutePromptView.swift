//
//  LandmarkReroutePromptView.swift
//  ParkHere
//
//  Created by Codex on 18/06/26.
//

import SwiftUI

struct LandmarkReroutePromptView: View {
    let candidate: LandmarkRerouteCandidate
    let onStay: () -> Void
    let onSwitch: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(uiImage: candidate.image)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: AppIcon.flip)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.brandPrimaryBlue)

                    Text(candidate.title)
                        .font(.title3Bold)
                        .foregroundStyle(.white)
                }

                Text(candidate.subtitle)
                    .font(.subheadlineReg)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)

                Text("This spot is \(savedDistanceText) closer than your current target.")
                    .font(.bodyBold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            VStack(spacing: 12) {
                Button("Switch Target", action: onSwitch)
                    .buttonStyle(.primaryStyle)

                Button("Stay on Current Route", action: onStay)
                    .buttonStyle(.secondaryStyle)
            }
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background(Color.surfaceSecondaryBlackSmoke.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal, 20)
    }

    private var savedDistanceText: String {
        let meters = Int(candidate.savedDistance.rounded())

        return "\(max(meters, 0)) m"
    }
}

#Preview {
    LandmarkReroutePromptView(
        candidate: LandmarkRerouteCandidate(
            index: 1,
            image: UIImage(resource: .imgLandmark),
            title: "Landmark 1",
            subtitle: "Nearest landmark",
            candidateDistance: 12,
            currentTargetDistance: 38,
            savedDistance: 26
        ),
        onStay: {},
        onSwitch: {}
    )
    .preferredColorScheme(.dark)
}

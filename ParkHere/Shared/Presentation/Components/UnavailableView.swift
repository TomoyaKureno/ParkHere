//
//  UnavailableView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 12/06/26.
//

import SwiftUI

struct UnavailableView: View {
    let opacity: CGFloat
    let systemImage: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let buttonAction: () -> Void

    init(
        opacity: CGFloat = 1.0,
        systemImage: String = "location.slash.fill",
        title: String = "Location Access is Off",
        subtitle: String = "Turn on your location services to save your parking spot.",
        buttonTitle: String = "Open Settings",
        buttonAction: (() -> Void)? = nil
    ) {
        self.opacity = opacity
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction ?? Self.openSettingsAction
    }

    var body: some View {
        ZStack {
            Color.surfacePrimaryBlack
                .opacity(opacity)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(alignment: .center, spacing: 24) {
                    ZStack(alignment: .center) {
                        Circle()
                            .fill(Color.surfaceSecondaryBlackSmoke)
                            .opacity(0.5)
                            .frame(width: 154)
                        
                        Image(systemName: systemImage)
                            .foregroundStyle(Color.surfaceSecondaryWhite)
                            .font(Font.system(size: 69))
                            .opacity(0.5)
                    }
                    
                    VStack(alignment: .center, spacing: 12) {
                        Text(title)
                            .font(.titleBold)
                            .foregroundStyle(Color.surfaceSecondaryWhite)
                        
                        Text(subtitle)
                            .font(.subheadlineReg)
                            .opacity(0.5)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(width: 323)
                
                Spacer()
                
                Button {
                    buttonAction()
                } label: {
                    Text(buttonTitle)
                        .foregroundStyle(Color.surfaceSecondaryWhite)
                }
                .buttonStyle(.primaryStyle)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private static var openSettingsAction: () -> Void {
        {
            Task { @MainActor in
                openSettings()
            }
        }
    }

    @MainActor
    private static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

extension UnavailableView {
    static var motion: UnavailableView {
        UnavailableView(
            systemImage: "figure.walk.motion.trianglebadge.exclamationmark",
            title: "Motion Access is Off",
            subtitle: "Turn on your motion usage services to save your parking spot and Landmarks Altitude.",
            buttonTitle: "Open Settings"
        )
    }
}

#Preview("Preview Dark Mode") {
    UnavailableView(
        systemImage: "location.slash.fill",
        title: "Location Access is Off",
        subtitle: "Turn on your location services to save your parking spot and capture landmarks",
        buttonTitle: "Open Settings"
    )
        .preferredColorScheme(.dark)
}

#Preview("Preview Light Mode") {
    UnavailableView(
        systemImage: "location.slash.fill",
        title: "Location Access is Off",
        subtitle: "Turn on your location services to save your parking spot and capture landmarks",
        buttonTitle: "Open Settings"
    )
}

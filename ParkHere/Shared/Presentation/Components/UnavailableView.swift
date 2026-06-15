//
//  UnavailableView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 12/06/26.
//

import SwiftUI

struct UnavailableView: View {
    var opacity: Double = 1
    var systemImage: String = "location.slash.fill"
    var title: String = "Location Access is Off"
    var subtitle: String = "Turn on your location services to save your parking spot and capture waypoints"
    
    var body: some View {
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
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            Text("Open Settings")
                .foregroundStyle(Color.surfaceSecondaryWhite)
        }
        .buttonStyle(.primaryStyle)
    }
}

extension UnavailableView {
    static var motion: UnavailableView {
        UnavailableView(
            systemImage: "figure.walk.motion.trianglebadge.exclamationmark",
            title: "Motion Access is Off",
            subtitle: "Turn on your motion usage services to save your parking spot and Landmarks Altitude."
        )
    }
}

#Preview("Preview Dark Mode") {
    UnavailableView()
        .preferredColorScheme(.dark)
}

#Preview("Preview Light Mode") {
    UnavailableView()
}

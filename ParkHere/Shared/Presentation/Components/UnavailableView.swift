//
//  UnavailableView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 12/06/26.
//

import SwiftUI

struct UnavailableView: View {
    var body: some View {
        Spacer()
        VStack(alignment: .center, spacing: 24) {
            ZStack(alignment: .center) {
                Circle()
                    .fill(Color.surfaceSecondaryBlackSmoke)
                    .opacity(0.5)
                    .frame(width: 154)
                
                Image(systemName: "location.slash.fill")
                    .foregroundStyle(Color.surfaceSecondaryWhite)
                    .font(Font.system(size: 69))
                    .opacity(0.5)
            }
            
            VStack(alignment: .center, spacing: 12) {
                Text("Location Access is Off")
                    .font(.titleBold)
                    .foregroundStyle(Color.surfaceSecondaryWhite)
                
                Text("Turn on your location services to save your parking spot and capture waypoints")
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

#Preview("Preview Dark Mode") {
    UnavailableView()
        .preferredColorScheme(.dark)
}

#Preview("Preview Light Mode") {
    UnavailableView()
}

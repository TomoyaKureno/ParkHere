//
//  HomeEmptyStateView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 11/06/26.
//

import SwiftUI

struct HomeEmptyStateView: View {
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .center, spacing: 24) {
                ZStack(alignment: .center) {
                    Circle()
                        .fill(Color.surfaceSecondaryBlackSmoke)
                        .opacity(0.5)
                        .frame(width: 154)
                    
                    Image(systemName: "car.side.and.exclamationmark")
                        .foregroundStyle(Color.surfaceSecondaryWhite)
                        .font(Font.system(size: 69))
                        .opacity(0.5)
                }
                
                VStack(alignment: .center, spacing: 12) {
                    Text("No Parking Saved")
                        .font(.titleBold)
                        .foregroundStyle(Color.surfaceSecondaryWhite)
                    
                    Text("Save your parking spot and capture waypoints to find your way back your parked car")
                        .font(.subheadlineReg)
                        .opacity(0.5)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 323)
        }
    }
}

#Preview("Preview Dark Mode") {
    HomeEmptyStateView()
        .preferredColorScheme(.dark)
}

#Preview("Preview Light Mode") {
    HomeEmptyStateView()
}

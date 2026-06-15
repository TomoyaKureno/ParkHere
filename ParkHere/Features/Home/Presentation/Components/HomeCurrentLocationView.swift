//
//  HomeCurrentLocationView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 11/06/26.
//

import SwiftUI

struct HomeCurrentLocationView: View {
    let landmark: CurrentLandmark

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Image(systemName: "location.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.brandPrimaryBlue)
            
            VStack(alignment: .leading) {
                Text("Current location")
                    .foregroundStyle(Color.surfaceSecondaryWhite)
                    .font(.footnoteSemiBold)
                    .opacity(0.5)
                
                Text(landmark.title)
                    .foregroundStyle(Color.surfaceSecondaryWhite)
                    .font(.subheadlineBold)
                
                Text(landmark.subtitle)
                    .foregroundStyle(Color.surfaceSecondaryWhite)
                    .font(.footnoteSemiBold)
                    .opacity(0.5)
                    .lineLimit(2)
            }
        }
    }
}

#Preview("Preview Dark Mode") {
    HomeCurrentLocationView(landmark: .loading)
        .preferredColorScheme(.dark)
}

#Preview("Preview Light Mode") {
    HomeCurrentLocationView(landmark: .loading)
}

//
//  HomeCurrentLocationView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 11/06/26.
//

import SwiftUI

struct HomeCurrentLocationView: View {
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
                
                Text("Mega Mall, Batam")
                    .foregroundStyle(Color.surfaceSecondaryWhite)
                    .font(.subheadlineBold)
                
                Text("Jl. Jend. Sudirman No.1, Batam Center, Batam")
                    .foregroundStyle(Color.surfaceSecondaryWhite)
                    .font(.footnoteSemiBold)
                    .opacity(0.5)
            }
        }
    }
}

#Preview("Preview Dark Mode") {
    HomeCurrentLocationView()
        .preferredColorScheme(.dark)
}

#Preview("Preview Light Mode") {
    HomeCurrentLocationView()
}

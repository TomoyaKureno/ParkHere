//
//  HomeIconView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 04/06/26.
//

import SwiftUI

struct HomeIconView: View {
    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(Color.brandAccentBlue)
                .frame(width: 101)
            
            Circle()
                .fill(Color.brandAccentLightBlue)
                .frame(width: 85)
                .opacity(0.3)
            
            Circle()
                .fill(Color.brandAccentLightBlue)
                .frame(width: 64)
                .opacity(0.3)
            
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(Color.brandPrimaryBlue)
                .font(.system(size: 42))
                
        }
    }
}

#Preview {
    HomeIconView()
}

#Preview {
    HomeIconView()
        .preferredColorScheme(.dark)
}

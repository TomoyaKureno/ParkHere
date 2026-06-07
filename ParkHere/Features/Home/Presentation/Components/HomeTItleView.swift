//
//  HomeTItleView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 04/06/26.
//

import SwiftUI

struct HomeTItleView: View {
    @State var title: String
    @State var description: String
    
    var body: some View {
        VStack (alignment: .center, spacing: 12) {
            Text(title)
                .font(.titleBold)
               
            Text(description)
                .font(.subheadlineReg)
                .multilineTextAlignment(.center)
                .opacity(0.5)
        }
        .foregroundStyle(Color.surfaceSecondaryWhite)
        .frame(width: 303)
    }
}

#Preview {
    HomeTItleView(
        title: "Save Your Parking Spot",
        description: "We'll capture your current location so you can easily navigate back to your parking."
    )
}

#Preview {
    HomeTItleView(
        title: "Save Your Parking Spot",
        description: "We'll capture your current location so you can easily navigate back to your parking."
    )
    .preferredColorScheme(.dark)
}

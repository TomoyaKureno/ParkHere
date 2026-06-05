//
//  HomeView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 04/06/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color.surfacePrimaryBlack
                .ignoresSafeArea()
            
            VStack (spacing: 38) {
                Spacer()
                
                VStack (spacing: 28) {
                    HomeIconView()
                    
                    HomeTItleView(
                        title: "Save Your Parking Spot",
                        description: "We'll capture your current location so you can easily navigate back to your parking."
                    )
                    
                    HomeCardView(hasSavedLocation: false)
                }
                
                Button {
                    print("Tapped")
                } label: {
                    Text("Save Parking Spot")
                        .foregroundStyle(Color.white)
                        .bold()
                        .frame(height: 50)
                        .padding(.horizontal, 34)
                        .background(Color.brandPrimaryBlue)
                        .clipShape(.capsule)
                }

                
                Spacer()
            }
        }
    }
}

#Preview {
    HomeView()
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}

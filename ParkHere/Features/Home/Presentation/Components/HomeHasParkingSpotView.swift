//
//  HomeHasParkingSpotView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 11/06/26.
//

import SwiftUI

struct HomeHasParkingSpotView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 34) {
            VStack(alignment: .center, spacing: 12) {
                Text("Parking Spot Saved")
                    .foregroundStyle(Color.surfaceSecondaryWhite)
                    .font(.titleBold)
                
                Text("We’ve saved your car location so you can find it again anytime")
                    .foregroundStyle(Color.surfaceSecondaryWhite)
                    .font(.subheadlineReg)
                    .opacity(0.5)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 324)
            
            ZStack {
                Image(.homeSavedImg)
                    .cornerRadius(24)
                
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(LinearGradient(
                            stops: [
                                .init(color: .surfacePrimaryBlackTransparent, location: 0),
                                .init(color: .surfacePrimaryBlack, location: 0.47),
                                .init(color: .surfacePrimaryBlack, location: 0.66),
                                .init(color: .surfacePrimaryBlack, location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 340, height: 200)
                        .cornerRadius(24)
                }
                
                VStack(alignment: .leading) {
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 4) {
                        HStack(alignment: .center) {
                            Image(systemName: "mappin")
                                .foregroundStyle(Color.brandPrimaryBlue)
                                .font(Font.system(size: 20))
                            
                            Text("Car Parked")
                                .font(.bodyBold)
                                .foregroundStyle(Color.brandPrimaryBlue)
                        }
                        
                        Spacer()
                        
                        Text("08.45")
                            .font(.footnoteBold)
                            .foregroundStyle(Color.surfaceSecondaryWhite)
                            .opacity(0.5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    Divider()
                        .background(Color.surfaceSecondaryBlackSmoke)
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading) {
                        Text("Mega Mall")
                            .font(.bodyBold)
                            .foregroundStyle(Color.surfaceSecondaryWhite)
                        
                        Text("Jl. Jend. Sudirman No.1, Batam Center, Batam")
                            .font(.footnoteReg)
                            .foregroundStyle(Color.surfaceSecondaryWhite)
                            .opacity(0.5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .frame(width: 338, height: 450)
        }
    }
}

#Preview("Preview Dark Mode") {
    HomeHasParkingSpotView()
        .preferredColorScheme(.dark)
}

#Preview("Preview Light Mode") {
    HomeHasParkingSpotView()
}

//
//  HomeCardView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 04/06/26.
//

import SwiftUI

struct HomeCardView: View {
    @Binding var hasSavedLocation: Bool

    var body: some View {
        VStack (spacing: 32) {
            HStack {
                HStack (alignment: .center, spacing: 4) {
                    Image(systemName: AppIcon.mapPin)
                        .foregroundStyle(hasSavedLocation ? Color.brandPrimaryBlue : Color.surfaceSecondaryWhite)
                    
                    if (hasSavedLocation) {
                        Text("Your saved location")
                            .font(.footnoteBold)
                            .foregroundStyle(Color.brandPrimaryBlue)
                    } else {
                        Text("Your current location")
                            .font(.footnoteBold)
                            .opacity(0.5)
                    }
                    
                }
                
                Spacer()
                
                if (!hasSavedLocation) {
                    Button {
                        print("Pressed")
                    } label: {
                        HStack (alignment: .center, spacing: 4) {
                            Image(systemName: AppIcon.refresh)
                                .foregroundStyle(Color.surfaceSecondaryWhite)
                            
                            Text("Refresh")
                                .font(.footnoteBold)
                                .opacity(0.5)
                                .foregroundStyle(Color.surfaceSecondaryWhite)
                        }
                    }
                }
            }
            
            HStack (alignment: .center, spacing: 12) {
                Image(.home)
                    .frame(width: 106, height: 97)
                    .clipShape(.rect(cornerRadius: 14))
                
                VStack (alignment: .leading, spacing: 6) {
                    Text("Mega Mall")
                        .foregroundStyle(Color.surfaceSecondaryWhite)
                        .font(.bodyBold)
                    
                    Text("Jl. Jend. Sudirman No.1, Batam Center, Batam")
                        .font(.footnoteReg)
                        .foregroundStyle(Color.surfaceSecondaryWhite)
                        .opacity(0.5)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(width: 340)
        .glassEffect(in: .rect(cornerRadius: 16.0))
    }
}

#Preview("Preview Light Mode") {
    @Previewable @State var hasSavedLocation: Bool = false

    HomeCardView(hasSavedLocation: $hasSavedLocation)
}

#Preview("Preview Dark Mode") {
    @Previewable @State var hasSavedLocation: Bool = false

    HomeCardView(hasSavedLocation: $hasSavedLocation)
        .preferredColorScheme(.dark)
}

#Preview("Preview Dark Mode with Saved Location") {
    @Previewable @State var hasSavedLocation: Bool = true

    HomeCardView(hasSavedLocation: $hasSavedLocation)
        .preferredColorScheme(.dark)
}

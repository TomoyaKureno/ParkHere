//
//  HomeCardView.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 04/06/26.
//

import SwiftUI

struct HomeCardView: View {
    @State var hasSavedLocation: Bool

    var body: some View {
        VStack (spacing: 32) {
            HStack {
                HStack (alignment: .center, spacing: 4) {
                    Image(systemName: "mappin")
                        .foregroundStyle(Color.surfaceSecondaryWhite)
                    
                    if (hasSavedLocation) {
                        Text("Your saved location")
                            .font(.footnote)
                            .opacity(0.5)
                    } else {
                        Text("Your current location")
                            .font(.footnote)
                            .opacity(0.5)
                    }
                    
                }
                
                Spacer()
                
                if (!hasSavedLocation) {
                    Button {
                        print("Pressed")
                    } label: {
                        HStack (alignment: .center, spacing: 4) {
                            Image(systemName: "arrow.trianglehead.clockwise")
                                .foregroundStyle(Color.surfaceSecondaryWhite)
                            
                            Text("Refresh")
                                .font(.footnote)
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
                        .font(.body)
                        .bold()
                    
                    Text("Jl. Jend. Sudirman No.1, Batam Center, Batam")
                        .font(.footnote)
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

#Preview {
    HomeCardView(hasSavedLocation: false)
}

#Preview {
    HomeCardView(hasSavedLocation: false)
        .preferredColorScheme(.dark)
}

#Preview {
    HomeCardView(hasSavedLocation: true)
        .preferredColorScheme(.dark)
}

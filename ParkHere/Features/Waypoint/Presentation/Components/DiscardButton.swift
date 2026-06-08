//
//  DiscardButton.swift
//  ParkHere
//
//  Created by Kelly Angeline on 08/06/26.
//

import SwiftUI

struct DiscardButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: AppIcon.xMark)
                .font(.footnote)
                .foregroundColor(.white)
                .padding(4)
                .clipped()
                .background(Color(.gray))
                .clipShape(Circle())
        }
    }
}

#Preview {
    DiscardButton(action: {})
}

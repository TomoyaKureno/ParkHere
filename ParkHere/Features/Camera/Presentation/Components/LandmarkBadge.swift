//
//  LandmarkBadge.swift
//  ParkHere
//
//  Created by Kelly Angeline on 05/06/26.
//

import SwiftUI

struct LandmarkBadge: View {
    var text: String
    var color: Color
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(color)
            .clipShape(Capsule())
            .padding(8)
    }
}

#Preview {
    LandmarkBadge(text: "Hello", color: .blue)
}

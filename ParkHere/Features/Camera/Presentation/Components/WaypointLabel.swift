//
//  WaypointLabel.swift
//  ParkHere
//
//  Created by Kelly Angeline on 05/06/26.
//

import SwiftUI

struct WaypointLabel: View {
    var text: String
    var color: Color
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(.white)
            .background(color)
            .clipShape(Capsule())
            .padding(8)
    }
}

#Preview {
    WaypointLabel(text: "Hello", color: .blue)
}

//
//  TrackerMetricValueRow.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 20/06/26.
//

import SwiftUI

struct TrackerMetricValueRow: View {
    let systemImage: String?
    let text: String

    init(systemImage: String? = nil, text: String) {
        self.systemImage = systemImage
        self.text = text
    }

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .fixedSize()
            }

            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .layoutPriority(1)
        }
        .font(.title.bold())
    }
}

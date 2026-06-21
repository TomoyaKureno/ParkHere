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
    let font: Font
    let lineLimit: Int?
    let usesAdaptiveFont: Bool

    init(
        systemImage: String? = nil,
        text: String,
        font: Font = .title.bold(),
        lineLimit: Int? = 2,
        usesAdaptiveFont: Bool = false
    ) {
        self.systemImage = systemImage
        self.text = text
        self.font = font
        self.lineLimit = lineLimit
        self.usesAdaptiveFont = usesAdaptiveFont
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .fixedSize()
            }

            Text(text)
                .lineLimit(lineLimit)
                .multilineTextAlignment(.leading)
                .allowsTightening(true)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .font(metricFont)
    }

    private var metricFont: Font {
        guard usesAdaptiveFont else { return font }

        switch text.count {
        case 0...8:
            return Font.title.bold()
        case 9...12:
            return Font.title2.bold()
        case 13...18:
            return Font.headline.bold()
        default:
            return Font.subheadline.bold()
        }
    }
}

//
//  HeadingCalibrationHintView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 13/06/26.
//

import SwiftUI

struct HeadingCalibrationHintView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: AppIcon.unavailable)

            Text("Kalibrasi kompas: gerakkan iPhone membentuk angka 8")
        }
        .font(.footnoteReg)
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.35))
        .clipShape(Capsule())
        .multilineTextAlignment(.center)
    }
}

#Preview {
    ZStack {
        Color.surfacePrimaryBlack.ignoresSafeArea()
        HeadingCalibrationHintView()
    }
}

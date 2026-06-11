//
//  View+Extention.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 05/06/26.
//

import SwiftUI

// MARK: - Button Style
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? Color.white : Color.surfaceSecondaryWhite)
            .bold()
            .frame(width: 332, height: 50)
            .background(isEnabled ? Color.brandPrimaryBlue : Color.surfaceSecondaryWhite)
            .clipShape(.capsule)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.16)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.brandPrimaryBlue)
            .bold()
            .frame(width: 332, height: 50)
            .background(Color.gray.opacity(0.24))
            .clipShape(.capsule)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1 : 0.16)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primaryStyle: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }
    
    static var secondaryStyle: SecondaryButtonStyle {
        SecondaryButtonStyle()
    }
}

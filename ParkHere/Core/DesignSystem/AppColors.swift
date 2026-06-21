//
//  AppColors.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 04/06/26.
//

import SwiftUI

extension Color {
    // MARK: - Brand Color
    static let brandPrimaryBlue = Color(red: 10/255, green: 132/255, blue: 255/255)
    static let brandAccentGreen = Color(red: 19/255, green: 208/255, blue: 110/255)
    
    // MARK: - Surface Color
    static let surfacePrimaryBlack = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
        ? UIColor(red: 11/255, green: 11/255, blue: 11/255, alpha: 1)
        : UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
    })
    
    static let surfacePrimaryBlackTransparent = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
        ? UIColor(red: 11/255, green: 11/255, blue: 11/255, alpha: 0)
        : UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0)
    })
    
    static let surfaceSecondaryWhite = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
        ? UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
        : UIColor(red: 11/255, green: 11/255, blue: 11/255, alpha: 1)
    })
    
    static let surfaceSecondaryBlackSmoke = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
        ? UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1)
        : UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1)
    })

    static let surfaceCardWhiteSmoke = Color(red: 196/255, green: 196/255, blue: 196/255)
    static let surfaceCardDarkGray = Color(red: 41/255, green: 42/255, blue: 46/255)

    static let surfaceGray = Color(red: 183/255, green: 183/255, blue: 183/255)
}

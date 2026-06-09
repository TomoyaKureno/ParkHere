//
//  FeatureFlags.swift
//  ParkHere
//
//  Created by Marzandi Zahran Affandi Leta on 08/06/26.
//

import Foundation

enum FeatureFlags {
    #if DEBUG
    static var showAltimeterDebug: Bool = true
    #else
    static var showAltimeterDebug: Bool = false
    #endif
}

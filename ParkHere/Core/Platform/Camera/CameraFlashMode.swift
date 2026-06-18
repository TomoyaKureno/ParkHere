//
//  CameraFlashMode.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 01/06/26.
//

import AVFoundation

enum CameraFlashMode: String {
    case off
    case on
    case auto
    
    var avFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off:
            return .off
        case .on:
            return .on
        case .auto:
            return .auto
        }
    }
    
    var iconName: String {
        switch self {
        case .off:
            return "bolt.slash.fill"
        case .on:
            return "bolt.fill"
        case .auto:
            return "bolt.badge.automatic.fill"
        }
    }
}

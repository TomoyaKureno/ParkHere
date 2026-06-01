//
//  CameraState.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 26/05/26.
//

import UIKit

enum CameraState: Equatable {
    case takePhoto
    case previewPhoto(image: UIImage)
}

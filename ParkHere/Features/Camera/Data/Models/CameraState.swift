//
//  CameraState.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 26/05/26.
//

import CoreLocation
import Foundation
import UIKit

enum CameraState: Equatable {
    case takePhoto
    case previewPhoto(id: UUID, image: UIImage, location: CLLocation?)
}

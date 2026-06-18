//
//  LandmarkRerouteCandidate.swift
//  ParkHere
//
//  Created by Codex on 18/06/26.
//

import CoreLocation
import UIKit

struct LandmarkRerouteCandidate: Identifiable {
    let index: Int
    let image: UIImage
    let title: String
    let subtitle: String
    let candidateDistance: CLLocationDistance
    let currentTargetDistance: CLLocationDistance
    let savedDistance: CLLocationDistance

    var id: Int {
        index
    }
}

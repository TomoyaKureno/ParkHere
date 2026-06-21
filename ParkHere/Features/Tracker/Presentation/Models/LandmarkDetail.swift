//
//  LandmarkDetail.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 18/06/26.
//

import UIKit

struct LandmarkDetail: Identifiable {
    let landmarkIndex: Int
    let image: UIImage
    let title: String
    let subtitle: String
    let progressText: String
    let selectionState: LandmarkSelectionState

    var id: Int {
        landmarkIndex
    }
}

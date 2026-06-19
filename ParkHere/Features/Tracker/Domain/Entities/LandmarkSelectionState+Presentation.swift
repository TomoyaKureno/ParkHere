//
//  LandmarkSelectionState+Presentation.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 18/06/26.
//

extension LandmarkSelectionState {
    var canUseLandmark: Bool {
        self == .available
    }

    var buttonTitle: String {
        switch self {
        case .available:
            return "Go to This Landmark Instead"
        case .current:
            return "Current Landmark"
        case .passed:
            return "Already Passed"
        case .unavailable:
            return "Unavailable"
        }
    }
}

//
//  CurrentLandmark.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 13/06/26.
//

import Foundation

struct CurrentLandmark: Equatable, Sendable {
    let title: String
    let subtitle: String

    nonisolated static let loading = CurrentLandmark(
        title: "Finding nearby landmark",
        subtitle: "Getting your current location"
    )

    nonisolated static let unavailable = CurrentLandmark(
        title: "Location unavailable",
        subtitle: "Turn on location access to find nearby landmarks"
    )
}

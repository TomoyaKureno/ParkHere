//
//  AppRoute.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 05/06/26.
//

enum AppRoute: Hashable {
    case camera(retakeIndex: Int?)
    case tracker
    case landmark(isGallery: Bool)
}

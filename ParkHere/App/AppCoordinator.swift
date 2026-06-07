//
//  AppCoordinator.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 05/06/26.
//

import Combine
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard path.count > 0 else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}

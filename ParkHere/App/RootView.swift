//
//  RootView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 06/06/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var cameraViewModel = CameraViewModel()

    var body: some View {
        NavigationStack(path: $appCoordinator.path) {
            HomeView(
                onSaveParkingSpot: {
                    cameraViewModel.reset()
                    appCoordinator.push(.camera)
                },
                onFindParkingSpot: {
                    appCoordinator.push(.tracker)
                }
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .camera:
                    CameraView(viewModel: cameraViewModel) {
                        appCoordinator.push(.waypoint)
                    }

                case .waypoint:
                    WaypointView(viewModel: cameraViewModel) {
                        appCoordinator.popToRoot()
                    }

                case .tracker:
                    TrackerView(viewModel: cameraViewModel) {
                        appCoordinator.popToRoot()
                    }
                }
            }
        }
    }
}

#Preview {
    RootView()
}

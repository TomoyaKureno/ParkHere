//
//  RootView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 06/06/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var appCoordinator = AppCoordinator()

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
                    CameraView(onDone: {
                        appCoordinator.pop()
                    })
                case .tracker:
                    TrackerView(viewModel: cameraViewModel) {
                        appCoordinator.popToRoot()
                    }
                }
            }
        }
        .environmentObject(appCoordinator) // Share navigation
    }
}

#Preview {
    RootView()
}

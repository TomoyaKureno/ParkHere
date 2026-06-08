//
//  RootView.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 06/06/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var waypointStore = WaypointStore() //nb: observable object, without this, swiftui needs to recreate object and saved images could disappear. 

    var body: some View {
        NavigationStack(path: $appCoordinator.path) {
            HomeView(
                onSaveParkingSpot: {
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
                        appCoordinator.push(.waypoint)
                    })
                case .waypoint:
                    WaypointView(
                        onAddAnotherWaypoint: {
                            appCoordinator.pop()
                        },
                        onSaveParkingSpot: {
                            
                        }
                    )
                case .tracker:
                    TrackerView(onFoundIt: {})
                }
            }
        }
        .environmentObject(waypointStore) // Share photo list
        .environmentObject(appCoordinator) // Share navigation
    }
}

#Preview {
    RootView()
}

//
//  ParkHereApp.swift
//  ParkHere
//
//  Created by Fathariq Dimas on 26/05/26.
//

import SwiftData
import SwiftUI

@main
struct ParkHereApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LandmarkRecord.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

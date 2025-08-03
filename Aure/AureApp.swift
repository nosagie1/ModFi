//
//  AureApp.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/9/25.
//

import SwiftUI
import SwiftData

@main
struct AureApp: App {
    @StateObject private var appState = AppState()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Agency.self,
            Job.self,
            Payment.self,
        ])
        
        // Use persistent storage for data persistence
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If that fails, try to delete the old database and recreate
            do {
                let url = URL.applicationSupportDirectory.appending(path: "default.store")
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                
                let freshConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: [freshConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}

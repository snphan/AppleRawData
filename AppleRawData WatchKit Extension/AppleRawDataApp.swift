//
//  AppleRawDataApp.swift
//  AppleRawData WatchKit Extension
//
//  Created by Steven Phan on 2022-05-15.
//

import SwiftUI

@main
struct AppleRawDataApp: App {
    @StateObject private var workoutManager = WorkoutManager()
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }.environmentObject(workoutManager)
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}

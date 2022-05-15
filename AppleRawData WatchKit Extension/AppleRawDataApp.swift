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
    @StateObject private var imuManager = IMUManager()
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }.environmentObject(workoutManager)
                .environmentObject(imuManager)
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}

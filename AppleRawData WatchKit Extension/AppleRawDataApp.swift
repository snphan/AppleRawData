//
//  AppleRawDataApp.swift
//  AppleRawData WatchKit Extension
//
//  Created by Steven Phan on 2022-05-15.
//

import SwiftUI

@main
struct AppleRawDataApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}

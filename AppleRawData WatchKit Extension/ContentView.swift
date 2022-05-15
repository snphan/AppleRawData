//
//  ContentView.swift
//  AppleRawData WatchKit Extension
//
//  Created by Steven Phan on 2022-05-15.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var imuManager: IMUManager
    var body: some View {
        VStack {
            Text("Heart Rate: \(self.workoutManager.heartRate.formatted(.number.precision(.fractionLength(0)))) BPM")
                .padding()
            
            Text("a: \(imuManager.accel[0].formatted(.number.precision(.fractionLength(2)))), \(imuManager.accel[1].formatted(.number.precision(.fractionLength(2)))), \(imuManager.accel[2].formatted(.number.precision(.fractionLength(2))))")
        }.onAppear {
            workoutManager.requestAuthorization()
            workoutManager.startWorkout()
            imuManager.startAccelerometers()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

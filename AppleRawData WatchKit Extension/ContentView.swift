//
//  ContentView.swift
//  AppleRawData WatchKit Extension
//
//  Created by Steven Phan on 2022-05-15.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @State private var heartRate = 0
    @State private var O2Sat = 95
    
    var body: some View {
        VStack {
            Text("Heart Rate: \(self.heartRate.formatted(.number.precision(.fractionLength(0)))) BPM")
                .padding()
            Text("O2 Sat: \(self.O2Sat)%")
        }.onAppear {
            workoutManager.requestAuthorization()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

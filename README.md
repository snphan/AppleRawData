# Apple iOS: HealthKit & Core Motion

Day:  - 
Done: No
Due This Week?: No
Tags: Docs, Manuals

*This manual goes over how to make an iOS App that can get the heartRate from healthkit and acceleration from CoreMotion*

# General Setup

1. Make a new watch app and add some text the UI for placeholder heartrate and acceleration.

**ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {

    var body: some View {
        VStack {
            Text("Heart Rate: 100 BPM")
                .padding()
            Text("a: 0.1, 0.1, 0.1")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
```

# HealthKit

## Setup

1. In “Watch App Extension” > Signing and Capabilities, add HealthKit

![Screen Shot 2022-05-16 at 4.12.06 PM.png](Apple%20iOS%20HealthKit%20&%20Core%20Motion%20b01de5a3a85540af89140d5d1e648ae6/Screen_Shot_2022-05-16_at_4.12.06_PM.png)

1. In the “Watch App Extension” info.plist, add the following policies
    1. NSHealthUpdateUsageDescription
    2. NSHealthShareUsageDescription
    

## Authentication

1. Make another swift file to contain the WorkoutManager class. This class handles controlling a workout (which is where we get the live health data from.)
2. Referring to the documentation for [data types](https://developer.apple.com/documentation/healthkit/data_types), choose the data types for sharing and for reading that the watch will prompt the user for. Put the authorization in a method.

**WorkoutManager.swift**

```swift
import Foundation
import HealthKit

class WorkoutManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    @Published var heartRate: Double = 0
    
    func requestAuthorization() {
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
        }
    }
```

1. Make WorkoutManager a @StateObject at the app level so that it can be passed around each view. We need to set it as the environmentObject at the app level.

**AppleRawDataApp.swift**

```swift
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
```

1. Call the requestAuthorization method in the main “ContentView”

**ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        VStack {
            Text("Heart Rate: \(self.workoutManager.heartRate.formatted(.number.precision(.fractionLength(0)))) BPM")
                .padding()
            
            Text("a: 0.1, 0.1 0.1")
        }.onAppear {
            workoutManager.requestAuthorization()
        }
    }
}
```

1. When you next run the App, a screen should pop up asking you to authorize. For reprompt, click on Product > Clean Build Folder.

## Getting HeartRate

Based on [Running Workout Sessions](https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/running_workout_sessions)

1. Create the session to pause, start, stop the workout and the builder to get the data. We put this in startWorkout Method in the WorkoutManager.swift.

**WorkoutManager.swift**

```swift
class WorkoutManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    @Published var heartRate: Double = 0
    
    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        // Create the session
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            return
        }
        
        // Assign delegates to monitor the workout session and the builder
        session?.delegate = self
        builder?.delegate = self
        
        // Assign the live datasource object to workout builder.
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        
     
        // Start the workout session and begin data collection.
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // The workout has started.
        }
    }

		func requestAuthorization() {
		...
		}
}
```

1. Assign the session.delegate and builder.delegate to the class and then we need to declare what the delegate does. For the session, we define what happens when state of session changes and for the builder, we define what happens when new data comes in

**WorkoutManager.swift**

```swift
class WorkoutManager: NSObject, ObservableObject {
	...
}

// MARK: - HKLiveBuilderWorkoutDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            updateData(statistics)
        }
    }

}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        
        DispatchQueue.main.async {
            self.running = toState == .running
        }

        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    }
}
```

1. If we want buttons we can add control logic on when to start the workout, stop the workout, pause the workout and resume the workout. (Anyway, we need a self.running variable for HKWorkoutSessionDelegate to work so just make it anyways.)

**WorkoutManager.swift**

```swift
class WorkoutManager: NSObject, ObservableObject {
	...

// MARK: - Session State Control

    // The app's workout state.
    @Published var running = false

    func togglePause() {
        if running == true {
            self.pause()
        } else {
            resume()
        }
    }

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    func endWorkout() {
        session?.end()
    }
}

// MARK: - HKLiveBuilderWorkoutDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
	...
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {
	...
}
```

1. Notice that in the builder delegate of step 2, we throw the statistics, or the “data” to some updateData of the class. Let’s define that here. Make sure the updates to the @Published values occur in the main thread (use DispatchQueue.main.async). Here we POST the data to the endpoint in the url variable.

**WorkoutManager.swift**

```swift
class WorkoutManager: NSObject, ObservableObject {
	...
//MARK: - Update the data
    // We need to update the values in the main thread so pass that data we receive from the sensor into here
    
    func updateData(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        
        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                guard let url = URL(string: "http://192.168.1.78:8000/myapp/heart/adddata/")
                else {
                    return
                }
                
                var body : Data?
                do {
                    body = try JSONSerialization.data(withJSONObject: ["heartRate": self.heartRate])
                } catch {
                    print("can't make json")
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.httpBody = body
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                }.resume()
            default:
                print("nothing")
            }
        }
}

// MARK: - HKLiveBuilderWorkoutDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
	...
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {
	...
}
```

1. Add the startWorkout method to the onAppear in the ContentView.swift to start the workout on app bootup

**ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        VStack {
            Text("Heart Rate: \(self.workoutManager.heartRate.formatted(.number.precision(.fractionLength(0)))) BPM")
                .padding()
            
            Text("a: 0.1, 0.1 0.1")
        }.onAppear {
            workoutManager.requestAuthorization()
						workoutManager.startWorkout()
        }
    }
}
```

# Core Motion

1. Make an IMUManager Class to store the function for getting IMU data. Import CoreMotion and do the following to get the accelerometer data. Right now the refresh rate is set to 60 Hz

**IMUManager.swift**

```swift
import Foundation
import CoreMotion

class IMUManager: NSObject, ObservableObject {
    let motion = CMMotionManager()
    var timer: Timer?
    @Published var accel = [0.0, 0.0, 0.0]
    
    
    func startAccelerometers() {
        // Check if Hardware is available
        if self.motion.isAccelerometerAvailable {
            print("Accelerometer is available!")
            self.motion.accelerometerUpdateInterval = 1.0 / 60.0
            self.motion.startAccelerometerUpdates()
            
            let handler: CMAccelerometerHandler = {data, error in
                let x = data!.acceleration.x
                let y = data!.acceleration.y
                let z = data!.acceleration.z
                
                self.accel = [x, y, z]
            }
            
            motion.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: handler)
            
        } else {
            print("Accelerometer is not available")
        }
    }
}
```

1. Add the IMUManager to the environment object like workoutManager in the main app.

**AppleRawDataApp.swift**

```swift
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
```

1. Add the acceleration updates to the contentview

**ContentView.swift**

```swift
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
```

<aside>
💡 Note that the accelerometer is not simulated and works only when you have an actual device.

</aside>
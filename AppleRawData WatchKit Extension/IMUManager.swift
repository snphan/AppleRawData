//
//  IMUManager.swift
//  AppleRawData WatchKit Extension
//
//  Created by Steven Phan on 2022-05-15.
//

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

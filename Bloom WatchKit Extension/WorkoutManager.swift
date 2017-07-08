//
//  WorkoutManager.swift
//  Bloom
//
//  Created by Eric Hodgins on 2017-07-01.
//  Copyright © 2017 Eric Hodgins. All rights reserved.
//

import Foundation

class WorkoutManager {
    static let shared = WorkoutManager()
    private init() {}
    
    lazy var notificationCenter: NotificationCenter = {
        return NotificationCenter.default
    }()
    
    var workouts: [String] = []
    var currentExcercises: [String] = []
    private var currentExcercise: String?
    private var excerciseIndex: Int = 0
    var workoutStartDate: NSDate?
    var currentWorkout: String? {
        didSet {
            guard let workoutName = self.currentWorkout else { return }
            WatchConnectivityManager.requestExcercises(forWorkout: workoutName) { (excerciseNames) in
                self.currentExcercises = excerciseNames
                self.currentExcercise = self.currentExcercises[0]
                self.updateMaxReps()
            }
        }
    }
    var reps: Double?
    
    func nextExcercise() -> String {
        excerciseIndex = (excerciseIndex + 1) % currentExcercises.count
        return currentExcercises[excerciseIndex]
    }
    
    func updateMaxReps() {
        guard let workout = currentWorkout,
            let excercise = currentExcercise else { return }
        
        WatchConnectivityManager.requestMaxReps(forExcercise: excercise, inWorkout: workout) { (maxReps) in
            print(maxReps)
            self.reps = maxReps
        }
    }
    
    func save() {
        guard let reps = reps else { return }
        let orderNumber = excerciseIndex
        WatchConnectivityManager.save(reps: "\(reps)", orderNumber: "\(orderNumber)")
    }
}
























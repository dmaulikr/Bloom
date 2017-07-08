//
//  PhoneConnectivityManager.swift
//  Bloom
//
//  Created by Eric Hodgins on 2017-06-30.
//  Copyright © 2017 Eric Hodgins. All rights reserved.
//

import UIKit
import CoreData
import WatchConnectivity

let NotificationLiveWorkoutStarted = "NotificationLiveWorkoutStarted"
let NofiticationNewExcerciseBegan = "NotificationNewExcerciseBegan"

class PhoneConnectivityManager: NSObject {
    
    lazy var bloomFilter: BloomFilter = {
        return BloomFilter()
    }()
    
    lazy var notificationCenter: NotificationCenter = {
        return NotificationCenter.default
    }()
    
    var managedContext: NSManagedObjectContext!
    
    public init(managedContext: NSManagedObjectContext) {
        super.init()
        self.managedContext = managedContext
        setupNotifications()
    }
    
    func setupNotifications() {
        notificationCenter.addObserver(forName: NSNotification.Name(rawValue: NotificationLiveWorkoutStarted), object: nil, queue: nil) { (notification) in
            if let dateStarted = notification.userInfo?["StartDate"] as? NSDate,
                let name = notification.userInfo?["Name"] as? String,
                let excercises = notification.userInfo?["Excercises"] as? [String] {
                self.sendStateToWatch(date: dateStarted, name: name, excercises: excercises)
            }
        }
        
        notificationCenter.addObserver(forName: NSNotification.Name(rawValue: NofiticationNewExcerciseBegan), object: nil, queue: nil) { (notification) in
            // send excercise values to watch
        }
    }
    
    func sendStateToWatch(date: NSDate, name: String, excercises: [String]) {
        if WCSession.isSupported() {
            let session = WCSession.default()
            if session.isWatchAppInstalled {
                do {
                    let dictionary: [String: Any] = ["StartDate" : date,
                                      "Name": name,
                                      "Excercises": excercises]
                    try session.updateApplicationContext(dictionary) // Application Context transfers only transfer the most recent dictionary of data over.
                } catch {
                    print("ERROR (sendStateToWatch): \(error)")
                }
            }
        }
    }
    
    func sendExcerciseStateToWatch() {
        
    }
    
    func sendWorkoutsToWatch(replyHandler: (([String : Any]) -> Void)) {
        let workouts = bloomFilter.allWorkouts(inManagedContext: managedContext)
        let workoutNames = workouts.map({ (workoutTemplate) -> String in
            return workoutTemplate.name!
        })
        replyHandler(["Workouts": workoutNames])
    }
    
    func sendExcercisesToWatch(name: String, replyHandler: (([String : Any]) -> Void)) {
        let excercises = BloomFilter.excercises(forWorkout: name, inManagedContext: managedContext)
        WorkoutStateManager.shared.excercises = excercises
        replyHandler(["Excercises": excercises])
    }
    
    func sendMaxReps(forExcercise: String, replyHandler: (([String : Any]) -> Void)) {
        
    }

}

extension PhoneConnectivityManager: WCSessionDelegate {
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession did become inactive.")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession Did Deactivate.")
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession error: \(error.localizedDescription)")
            return
        }
        
        print("WCSession activation complete. activationState: \(activationState.rawValue)")
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print(applicationContext)
        // When workout starts on watch and then iPhone App is opened.
        /*
        if let startTime = applicationContext["StartDate"] as? NSDate {
            
            WorkoutStateManager.shared.startedOnWatch = true
            WorkoutStateManager.shared.startTime = startTime
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let window = appDelegate.window
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let liveWorkoutController = storyboard.instantiateViewController(withIdentifier: "Live") as! LiveWorkoutController
            liveWorkoutController.managedContext = WorkoutStateManager.shared.managedContext
            liveWorkoutController.workout = WorkoutStateManager.shared.workout
            
            
            let nav = storyboard.instantiateInitialViewController() as! UINavigationController
            let root = storyboard.instantiateViewController(withIdentifier: "Main") as! MainViewController
            root.managedContext = WorkoutStateManager.shared.managedContext
            nav.viewControllers = [root]
            window?.rootViewController = nav
            
            DispatchQueue.main.async {
                window?.rootViewController?.present(liveWorkoutController, animated: true, completion: nil)
            }
        }
         */
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        if let _ = message["NeedWorkouts"] as? Bool {
            sendWorkoutsToWatch(replyHandler: replyHandler)
        }
        
        if let workoutName = message["NeedExcercises"] as? String {
            WorkoutStateManager.shared.workoutName = workoutName
            sendExcercisesToWatch(name: workoutName, replyHandler: replyHandler)
        }
        
        if let _ = message["MaxReps"] as? Bool,
            let workout = message["Workout"] as? String,
            let excercise = message["Excercise"] as? String {
            
            let bloomFilter = BloomFilter()
            let maxReps = bloomFilter.fetchMaxValues(forExcercise: excercise, inWorkout: workout, withManagedContext: managedContext)
            let replyDict: [String: String] = ["MaxReps": "\(maxReps)"]
            replyHandler(replyDict)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print(message)
        if let workoutName = message["Name"] as? String,
            let startDate = message["StartDate"] as? NSDate {
            
            //Make sure the WorkoutProxy is nil. otherwise workout is still in progress
            //this message shouldn't happen though during a workout
            guard WorkoutStateManager.shared.workoutProxy == nil else { return }
            
            WorkoutStateManager.shared.startedOnWatch = true
            WorkoutStateManager.shared.workoutName = workoutName
            WorkoutStateManager.shared.startTime = startDate
            WorkoutStateManager.shared.managedContext = managedContext
            WorkoutStateManager.shared.createWorkout()// this creates the proxy workout as well.
            segueToLiveWorkout()
        }
        
        // Save called on watch
        if let reps = message["Reps"] as? String,
            let orderNumber = message["OrderNumber"] as? String {
            
            WorkoutStateManager.shared.save(reps: Double(reps)!, forOrderNumber: Int16(orderNumber)!)
        }
        
        if let _ = message["Finished"] as? Bool {
            
        }
    }
    
    func segueToLiveWorkout() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let window = appDelegate.window
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let liveWorkoutController = storyboard.instantiateViewController(withIdentifier: "Live") as! LiveWorkoutController
        liveWorkoutController.managedContext = WorkoutStateManager.shared.managedContext
        liveWorkoutController.workout = WorkoutStateManager.shared.workout
        
        
        let nav = storyboard.instantiateInitialViewController() as! UINavigationController
        let root = storyboard.instantiateViewController(withIdentifier: "Main") as! MainViewController
        root.managedContext = WorkoutStateManager.shared.managedContext
        nav.viewControllers = [root]
        window?.rootViewController = nav
        
        DispatchQueue.main.async {
            window?.rootViewController?.present(liveWorkoutController, animated: true, completion: nil)
        }
    }
}

















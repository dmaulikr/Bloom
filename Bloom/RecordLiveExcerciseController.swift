//
//  RecordLiveExcerciseController.swift
//  Bloom
//
//  Created by Eric Hodgins on 2017-01-07.
//  Copyright © 2017 Eric Hodgins. All rights reserved.
//

import UIKit
import CoreData

class RecordLiveExcerciseController: UIViewController {
    
    var managedContext: NSManagedObjectContext!
    var fetchRequest: NSFetchRequest<NSDictionary>!
    var bloomFilter: BloomFilter!
    
    var workoutName: String!
    var currentExcercise: Excercise!
    var excercises = [Excercise]()
    
    var maxReps: Double?
    
    weak var excerciseLabel: UILabel!
    var currentExcerciseIndex: Int = 0
    var currentCounter: Double = 0.0 // keeps track of the textfield in RecordLiveStatView
    
    var recordLiveStatView: RecordLiveStatView!
    var blurEffectView: UIVisualEffectView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentExcercise = excercises[0]
        excerciseLabel.text = excercises[currentExcerciseIndex].name!
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        maxReps = fetchMaxValues()
    }
    
    func fetchMaxValues() -> Double {
        bloomFilter = BloomFilter()
        return bloomFilter.fetchMaxValues(forExcercise: currentExcercise.name!, inWorkout: workoutName, withManagedContext: managedContext)
    }
    
    @IBAction func nextExcerciseTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.currentExcercise = self.excercises[self.currentExcerciseIndex]
            if self.currentExcercise.timeRecorded == nil {
                self.currentExcercise.timeRecorded = NSDate()
            }
            self.currentExcercise = self.getNextExcercise()
            self.excerciseLabel.text = self.currentExcercise.name!
            self.maxReps = self.fetchMaxValues()
        }
    }
    
    func getNextExcercise() -> Excercise {
        currentExcerciseIndex += 1
        if excercises.count > currentExcerciseIndex {
            return excercises[currentExcerciseIndex]
        }
        
        currentExcerciseIndex = 0
        return excercises[0]
    }
    
    @IBAction func repsButtonPushed(_ sender: Any) {
        addBlurEffect()
        showRecordView(withTitle: "Reps", andStat: Stat.Reps)
    }
    
    @IBAction func weightsButtonPushed(_ sender: Any) {
        addBlurEffect()
        showRecordView(withTitle: "Weight", andStat: Stat.Weight)
    }
    
    @IBAction func distanceButtonPushed(_ sender: Any) {
        addBlurEffect()
        showRecordView(withTitle: "Distance", andStat: Stat.Distance)
    }
    
    @IBAction func timeButtonPushed(_ sender: Any) {
        addBlurEffect()
        showRecordView(withTitle: "Time", andStat: Stat.Time)
    }
    
    func showRecordView(withTitle title: String, andStat stat: Stat) {
        retriveCurrentExcerciseValue(excercise: excercises[currentExcerciseIndex])
        
        recordLiveStatView = RecordLiveStatView(inView: view)
        recordLiveStatView.stat = stat
        recordLiveStatView.title.text = title
        recordLiveStatView.textField.text = "\(maxReps ?? 0)"
        currentCounter = maxReps ?? 0
        recordLiveStatView.plusButton.addTarget(self, action: #selector(RecordLiveExcerciseController.plusButtonPushed(sender:)), for: .touchUpInside)
        recordLiveStatView.minusButton.addTarget(self, action: #selector(RecordLiveExcerciseController.minusButtonPushed(sender:)), for: .touchUpInside)
        recordLiveStatView.saveButton.addTarget(recordLiveStatView, action: #selector(RecordLiveStatView.savePressed), for: .touchUpInside)
        recordLiveStatView.cancelButton.addTarget(recordLiveStatView, action: #selector(RecordLiveStatView.cancelPressed), for: .touchUpInside)
        
        recordLiveStatView.completionHandler = { (excerciseValue) in
            
            if let value = excerciseValue {
                self.saveExcerciseValue(forStat: self.recordLiveStatView.stat!, value: value)
            }
            
            UIView.animate(withDuration: 0.3, animations: {
                self.blurEffectView.alpha = 0
            }, completion: {_ in
                self.blurEffectView.removeFromSuperview()
            })
            
        }
        
        view.addSubview(recordLiveStatView)
    }
    
    func retriveCurrentExcerciseValue(excercise: Excercise) {
        print("\(String(describing: excercise.name)), Reps: \(excercise.reps)")
    }
    
    func saveExcerciseValue(forStat stat: Stat, value: String) {
        let excercise = excercises[currentExcerciseIndex]
        switch stat {
        case .Reps:
            excercise.reps = Double(value)!
            saveContext()
        case .Weight:
            excercise.weight = Double(value)!
            saveContext()
        case .Distance:
            excercise.distance = Double(value)!
            saveContext()
        case .Time:
            excercise.timeRecorded = NSDate()
        }
    }
    
    func saveContext() {
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("save error: \(error), description: \(error.userInfo)")
        }
    }
    
    func plusButtonPushed(sender: UIButton) {
        currentCounter += 1.0
        recordLiveStatView.textField.text = "\(currentCounter)"
    }
    
    func minusButtonPushed(sender: UIButton) {
        currentCounter -= 1.0
        recordLiveStatView.textField.text = "\(currentCounter)"
    }
    
    func addBlurEffect() {
        let blurEffect = UIBlurEffect(style: .light)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.frame
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
    }
}






























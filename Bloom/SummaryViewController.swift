//
//  SummaryViewController.swift
//  Bloom
//
//  Created by Eric Hodgins on 2017-05-31.
//  Copyright © 2017 Eric Hodgins. All rights reserved.
//

import UIKit
import CoreData

class SummaryViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var managedContext: NSManagedObjectContext!
    var workoutTypes: [NSDictionary] = []
    var workouts: [Workout] = []
    var isAllWorkouts: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        fetchWorkoutTypes()
    }
    
    func fetchWorkoutTypes() {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "WorkoutTemplate")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(WorkoutTemplate.name), ascending: true)]
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.returnsDistinctResults = true
        fetchRequest.propertiesToFetch = ["name"]
        
        do {
            workoutTypes = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Workout template fetch error: \(error.userInfo)")
        }
    }
    
    func fetchAllWorkouts() {
        let fetchRequest = NSFetchRequest<Workout>(entityName: "Workout")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Workout.name), ascending: true)]
        
        do {
            workouts = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("All workout fetch error: \(error.userInfo)")
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowExcercises" {
            let excerciseController = segue.destination as! ExcercisesController
            let cellIndex = tableView.indexPathForSelectedRow!
            excerciseController.managedContext = managedContext
            excerciseController.workoutName = workoutTypes[cellIndex.row]["name"] as! String
        }
    }
}

// Table View Delegate
extension SummaryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isAllWorkouts {
            return workouts.count
        }
        return workoutTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if isAllWorkouts {
            let workout = workouts[indexPath.row]
            cell.textLabel?.text = "\(workout.name!): \(workout.startTime!)"
        } else {
            cell.textLabel?.text = workoutTypes[indexPath.row]["name"] as? String
        }
        return cell
    }
}

// Table View Delegate
extension SummaryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let segmentView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 50))
            segmentView.backgroundColor = UIColor(colorLiteralRed: 9/255, green: 136/255, blue: 255/255, alpha: 1.0)
            
            let segmentControl = UISegmentedControl(frame: segmentView.frame)
            segmentControl.addTarget(self, action: #selector(SummaryViewController.segmentControlValueChanged(segment:)), for: .valueChanged)
            segmentControl.addTarget(self, action: #selector(SummaryViewController.segmentControlValueChanged(segment:)), for: .touchUpInside)
            segmentControl.insertSegment(withTitle: "Workouts", at: 0, animated: true)
            segmentControl.insertSegment(withTitle: "Show All", at: 1, animated: true)
            
            let font = UIFont.boldSystemFont(ofSize: 15)
            segmentControl.setTitleTextAttributes([NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.white], for: .normal)
            segmentControl.setTitleTextAttributes([NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.white], for: .selected)
            
            segmentView.addSubview(segmentControl)
            
            return segmentView
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isAllWorkouts == false {
            performSegue(withIdentifier: "ShowExcercises", sender: self)
        } else {
            performSegue(withIdentifier: "ShowWorkoutStats", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.contentView.backgroundColor = UIColor(colorLiteralRed: 100/255, green: 212/255, blue: 255/255, alpha: 1.0)
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.contentView.backgroundColor = UIColor.clear
    }
    
    func segmentControlValueChanged(segment: UISegmentedControl) {
        
        if segment.selectedSegmentIndex == 0 {
            // Show only types of workouts created
            isAllWorkouts = false
            tableView.reloadData()
        }
        
        if segment.selectedSegmentIndex == 1 {
            // Show All Workouts
            isAllWorkouts = true
            guard workouts.count == 0 else {
                tableView.reloadData()
                return
            }
            
            fetchAllWorkouts()
            tableView.reloadData()
        }
    }
}

























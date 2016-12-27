//
//  StartWorkoutController.swift
//  Bloom
//
//  Created by Eric Hodgins on 2016-12-25.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import UIKit


class StartWorkoutController: UIViewController {
    
    @IBOutlet weak var startButton: StartButton!
    @IBOutlet weak var editWorkoutButton: EditWorkoutButton!
    
    var workout: Workout!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = workout.name
        
        startButton.editWorkoutButton = editWorkoutButton
        startButton.addTarget(startButton, action: #selector(StartButton.animateGradient), for: .touchUpInside)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        startButton.setNeedsDisplay()
    }
}

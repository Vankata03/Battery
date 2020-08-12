//
//  ViewController.swift
//  Battery
//
//  Created by Ivan Terziev on 12.08.20.
//  Copyright © 2020 Ivan Terziev. All rights reserved.
//

import UIKit
import WatchConnectivity

class MainVC: UIViewController {

    // MARK: - Properties
    @IBOutlet var levelLabel: UILabel!
    @IBOutlet var stateLabel: UILabel!
    static let mainVC = MainVC()
    var level: Int = 0
    var state: UIDevice.BatteryState = .unknown
    var currentState: String = "unknown"
    var device = UIDevice.current
    
    
    // MARK: - App Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initiate setup
        setup()
        
        }

        
    // MARK: - Methods
    func setup() {
        
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Get the current battery level
        level = getLevel()
        levelLabel.text = ("Your battery is at \n \(level)%")
        
        // Get the current battery state
        currentState = getState()
        stateLabel.text = ("Your battery is \n \(currentState)")
        
        // Add observers to track for changes
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange(notification:)), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryStateDidChange(notification:)), name: UIDevice.batteryStateDidChangeNotification, object: nil)
    }
    
    func getLevel() -> Int {
        return Int(device.batteryLevel * 100)
    }
    
    func getState() -> String {
        
        // Get the state
        state = device.batteryState
        
        // Convert it into text
        switch state {
        case .full:
            return "full"
        case .charging:
            return "charging"
        case .unplugged:
            return "unplugged"
        default:
            return "unknown"
        }
    }
    
    
    // MARK: - Objective-C Methods
    @objc func batteryLevelDidChange(notification: NSNotification) {
        level = getLevel()
        levelLabel.text = ("Your battery is at \n \(level)%")
    }

    @objc func batteryStateDidChange(notification: NSNotification) {
        currentState = getState()
        stateLabel.text = ("Your battery is \n \(currentState)")
    }
}

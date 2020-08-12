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
    var lowPower: Bool = false
    
    
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
        
        // Get low power
        lowPower = getLowPower()
        setColor()
        
        // Add observers to track for changes
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange(notification:)), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryStateDidChange(notification:)), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(powerStateChanged), name: Notification.Name.NSProcessInfoPowerStateDidChange, object: nil)
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
    
    func getLowPower() -> Bool {
        return ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    func setColor() {
        if currentState == "charging" {
            stateLabel.textColor = UIColor.green
        } else if currentState == "unplugged" && level <= 20 {
            stateLabel.textColor = UIColor.red
        } else if currentState == "unplugged" && level > 20 && lowPower == true {
            stateLabel.textColor = UIColor.yellow
        } else {
            stateLabel.textColor = UIColor.init(named: "text")
        }
    }
    
    
    // MARK: - Objective-C Methods
    @objc func batteryLevelDidChange(notification: NSNotification) {
        level = getLevel()
        levelLabel.text = ("Your battery is at \n \(level)%")
        SessionHandler.shared.updateBattery()
        setColor()
    }

    @objc func batteryStateDidChange(notification: NSNotification) {
        currentState = getState()
        stateLabel.text = ("Your battery is \n \(currentState)")
        SessionHandler.shared.updateBattery()
        setColor()
    }
    
    @objc func powerStateChanged(notification: NSNotification) {
        lowPower = getLowPower()
        SessionHandler.shared.updateBattery()
        setColor()
    }
}

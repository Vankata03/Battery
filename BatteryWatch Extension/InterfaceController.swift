//
//  InterfaceController.swift
//  Battery WatchKit Extension
//
//  Created by Ivan Terziev on 12.08.20.
//  Copyright © 2020 Ivan Terziev. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import ClockKit

class InterfaceController: WKInterfaceController, WCSessionDelegate, WKExtensionDelegate {
    
    // MARK: - Properties
    @IBOutlet var levelLabel: WKInterfaceLabel!
    private var session = WCSession.default
    static let interfaceController = InterfaceController()
    var level: Int = 0
    var state: String = ""
    var lowPower: Bool = false
    
    
    // MARK: - App Lifecycle Methods
    // Activates when the app loads
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        
    }
    
    // Activates when you start launching the app
    override func willActivate() {
        super.willActivate()
        
        // Check if the session is suported
        if isSuported() {
            session.delegate = self
            session.activate()
        }
        
        // Get the current battery
        getBattery()
        
        // Update the complications
        let complicationServer = CLKComplicationServer.sharedInstance()
        guard complicationServer.activeComplications != nil else {
            return
        }
        for complications in complicationServer.activeComplications! {
            complicationServer.reloadTimeline(for: complications)
        }
        
    }
    
    // Activates when the app goes to sleep
    override func didDeactivate() {
        super.didDeactivate()
        
    }
    
    
    // MARK: - Methods
    // Returns if the session is supported
    private func isSuported() -> Bool {
        return WCSession.isSupported()
    }
    
    // Returns if the iPhone is reachable
    private func isReachable() -> Bool {
        return session.isReachable
    }
    
    // Used to get battery on launch
    private func getBattery() {
        repeat {
            requestLevel()
            requestState()
            requestLowPower()
            sleep (1)
        } while (level == 0 || level == -100)
        setColor()
    }
    
    // Requests battery level
    func requestLevel() {
        if isReachable() {
            // Request level
            session.sendMessage(["battery" : "level"], replyHandler: { (response) in
                self.level = response["level"] as! Int
                self.levelLabel.setText("\(self.level)%")
            }) { (error) in
                print(error)
            }
        }
    }
    
    // Requests battery state
    func requestState() {
        if isReachable() {
            // Request state
            session.sendMessage(["battery" : "state"], replyHandler: { (response) in
                self.state = response["state"] as! String
                self.setColor()
            }) { (error) in
                print(error)
            }
        }
    }
    
    // Requests low power state
    func requestLowPower() {
        if isReachable() {
            // Request lowPower
            session.sendMessage(["battery" : "lowPower"], replyHandler: { (response) in
                self.lowPower = response["lowPower"] as! Bool
                self.setColor()
            }) { (error) in
                print(error)
            }
        }
    }
    
    // Sets color based on level, state and low power
    func setColor() {
        if state == "charging" {
            levelLabel.setTextColor(UIColor.green)
        } else if state == "unplugged" && level < 20 {
            levelLabel.setTextColor(UIColor.red)
        } else if lowPower == true && state == "unplugged" && level > 20 {
            levelLabel.setTextColor(UIColor.yellow)
        } else {
            levelLabel.setTextColor(UIColor.white)
        }
    }
    
    // Updates values when it receives them
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        // Update level
        if (message["level"] != nil) {
            self.level = message["level"] as! Int
            self.levelLabel.setText("\(self.level)%")
            self.setColor()
        }
        
        // Update state
        if (message["state"] != nil) {
            self.state = message["state"] as! String
            self.setColor()
        }
        
        // Update lowPower
        if (message["lowPower"] != nil) {
            self.lowPower = message["lowPower"] as! Bool
            self.setColor()
        }
    }
    
    
    // MARK: - WCSessionDelegate Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
}

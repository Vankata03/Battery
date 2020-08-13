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

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    // MARK: - Properties
    @IBOutlet var levelLabel: WKInterfaceLabel!
    private var session = WCSession.default
    var level: Int = 0
    var state: String = ""
    var lowPower: Bool = false
    
    
    // MARK: - App Lifecycle Methods
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        
    }
    
    override func willActivate() {
        super.willActivate()
        
        // Check if the session is suported
        if isSuported() {
            session.delegate = self
            session.activate()
        }
        
        // Get the current battery
        getBattery()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
        
    }
    
    
    // MARK: - Methods
    private func isSuported() -> Bool {
        return WCSession.isSupported()
    }
    
    private func isReachable() -> Bool {
        return session.isReachable
    }
    
    // Used to get battery on launch
    private func getBattery() {
        repeat {
            requestLevel()
            sleep (1)
        } while (level == 0 || level == -100)
        setColor()
    }
    
    func requestLevel() {
        if isReachable() {
            
            // Request level
            session.sendMessage(["battery" : "level"], replyHandler: { (response) in
                self.level = response["level"] as! Int
                self.levelLabel.setText("\(self.level)%")
            }) { (error) in
                print(error)
            }
            
            // Request state
            session.sendMessage(["battery" : "state"], replyHandler: { (response) in
                self.state = response["state"] as! String
                self.setColor()
            }) { (error) in
                print(error)
            }
            
            // Request lowPower
            session.sendMessage(["battery" : "lowPower"], replyHandler: { (response) in
                self.lowPower = response["lowPower"] as! Bool
                self.setColor()
            }) { (error) in
                print(error)
            }
            
        }
    }
    
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

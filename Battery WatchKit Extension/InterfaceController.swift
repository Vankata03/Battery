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
    
    private func getBattery() {
        repeat {
            requestLevel()
            sleep (1)
        } while (level == 0 || level == -100)
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
                setColor()
                
            }) { (error) in
                print(error)
            }
        }
    }
    
    func setColor() {
        if state == "charging" {
            
        } else if state == "unplugged" && level < 20 {
            
        } else {
            
        }
    }
    
    
    // MARK: - WCSessionDelegate Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
}

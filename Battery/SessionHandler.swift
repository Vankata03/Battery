//
//  SessionHandler.swift
//  Battery
//
//  Created by Ivan Terziev on 12.08.20.
//  Copyright © 2020 Ivan Terziev. All rights reserved.
//

import Foundation
import WatchConnectivity

class SessionHandler: NSObject, WCSessionDelegate {
    
    // MARK: - Properties
    static let shared = SessionHandler()
    private var session = WCSession.default

    
    // MARK: - Init
    override init() {
        super.init()
        
        if isSuported() {
            session.delegate = self
            session.activate()
        }
    }
    
    
    // MARK: - Session Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
                print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        self.session.activate()
    }
    
    
    // MARK: - Methods
    func isSuported() -> Bool {
        return WCSession.isSupported()
    }
    
    private func isReachable() -> Bool {
        return session.isReachable
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        // Update level
        if message["battery"] as? String == "level" {
            replyHandler(["level" : MainVC.mainVC.getLevel()])
        }
        
        // Update state
        if message["battery"] as? String == "state" {
            replyHandler(["state" : MainVC.mainVC.getState()])
        }
        
        // Update lowPower
        if message["battery"] as? String == "lowPower" {
            replyHandler(["lowPower" : MainVC.mainVC.getLowPower()])
        }
    }
    
    func updateBattery() {
        if isReachable() {
            
            // Update level
            session.sendMessage(["level" : MainVC.mainVC.getLevel()], replyHandler: nil) { (error) in
                print(error)
            }
            
            // Update state
            session.sendMessage(["state" : MainVC.mainVC.getState()], replyHandler: nil) { (error) in
                print(error)
            }
            
            // Update lowPower
            session.sendMessage(["lowPower" : MainVC.mainVC.getLowPower()], replyHandler: nil) { (error) in
                print("error")
            }
        }
    }
}

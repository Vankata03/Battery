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
    
    
    // MARK: - Methods
    func isSuported() -> Bool {
        return WCSession.isSupported()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
                print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        self.session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if message["battery"] as? String == "level" {
            replyHandler(["level" : MainVC.mainVC.getLevel()])
        }
        if message["battery"] as? String == "state" {
            replyHandler(["state" : MainVC.mainVC.getState()])
        }
    }
}

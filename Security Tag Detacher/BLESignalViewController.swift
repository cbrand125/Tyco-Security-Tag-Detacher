//
//  BLESignalViewController.swift
//  Security Tag Detacher
//
//  Created by Cody Brand on 3/29/16.
//  Copyright © 2016 M E 440W Tyco Group. All rights reserved.
//

import UIKit

class BLESignalViewController: UIViewController {
    
    var QRValue : String?
    @IBOutlet weak var QRLabel: UILabel!
    
    var timerTXDelay: NSTimer?
    var allowTX = true
    var lastMessage: UInt8 = 255
    
    override func viewDidLoad() {
        super.viewDidLoad()
        QRLabel.text = QRValue
        
        //watch Bluetooth connection
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLESignalViewController.connectionChanged(_:)), name: BLEServiceChangedStatusNotification, object: nil)
        
        //start the Bluetooth discovery process
        btDiscoverySharedInstance.startScanning()
    }
    
    func authorize() -> UInt8 {
        //normally, this will check database/JSON file for permission on QR code
        return UInt8(10)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BLEServiceChangedStatusNotification, object: nil)
    }
    
    @IBAction func detachButtonAction(sender: UIButton) {
        sendMessage(authorize())
    }
    
    func connectionChanged(notification: NSNotification) {
        // Connection status changed.
        let userInfo = notification.userInfo as! [String: Bool]
        
        dispatch_async(dispatch_get_main_queue(), {
            if let isConnected: Bool = userInfo["isConnected"] {
                if isConnected {
                }
            }
        });
    }
    
    func sendMessage(message: UInt8) {
        if !allowTX {
            return
        }
        
        //send message to Arduino
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeMessage(message)
            
            // Start delay timer
            allowTX = false
            if timerTXDelay == nil {
                timerTXDelay = NSTimer.scheduledTimerWithTimeInterval(
                    0.1,
                    target: self,
                    selector: #selector(BLESignalViewController.timerTXDelayElapsed),
                    userInfo: nil,
                    repeats: false)
            }
        }
    }
    
    func timerTXDelayElapsed() {
        self.allowTX = true
        self.stopTimerTXDelay()
        
        self.sendMessage(authorize())
    }
    
    func stopTimerTXDelay() {
        if self.timerTXDelay == nil {
            return
        }
        
        timerTXDelay?.invalidate()
        self.timerTXDelay = nil
    }
    
}

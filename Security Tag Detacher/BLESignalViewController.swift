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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        QRLabel.text = QRValue
        navigationItem.title = QRValue
        
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
        //send message to Arduino
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeMessage(message)
        }
    }
    
}

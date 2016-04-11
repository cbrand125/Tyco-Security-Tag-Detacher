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
    let model = Model.sharedInstance
    
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemDescription: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = model.getItemNameForIdentifier(QRValue!)
        itemDescription.text = model.getItemDescriptionForIdentifier(QRValue!)
        itemImage.downloadedFrom(link: model.getItemPictureLinkForIdentifier(QRValue!)!, contentMode: UIViewContentMode.ScaleAspectFit)
        
        
        //watch Bluetooth connection
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLESignalViewController.connectionChanged(_:)), name: BLEServiceChangedStatusNotification, object: nil)
        
        //start the Bluetooth discovery process
        btDiscoverySharedInstance.setID(QRValue!)
        btDiscoverySharedInstance.startScanning()
    }
    
    func authorize() -> UInt8 {
        if let userID = UIDevice.currentDevice().identifierForVendor {
            if let purchaserID = model.getItemPurchaserIDForIdentifier(QRValue!) {
                if purchaserID == userID.UUIDString {
                    if let authCode = model.getItemAuthorizationCodeForIdentifier(QRValue!) {
                        return authCode
                    }
                }
            }
        }
        
        let alert = UIAlertController(title: "Authorization Failed", message: "You are not the purchaser for this item.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
        return UInt8(0)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BLEServiceChangedStatusNotification, object: nil)
    }
    
    @IBAction func detachButtonAction(sender: UIButton) {
        //for now, we assume the item has been purchased already always
        if let userID = UIDevice.currentDevice().identifierForVendor {
            model.setItemPurchaserIDForIdentifier(QRValue!, purchaser: userID.UUIDString)
        }
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

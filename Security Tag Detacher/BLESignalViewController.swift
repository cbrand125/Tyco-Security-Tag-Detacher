//
//  BLESignalViewController.swift
//  Security Tag Detacher
//
//  Created by Cody Brand on 3/29/16.
//  Copyright © 2016 M E 440W Tyco Group. All rights reserved.
//

import UIKit

protocol BLESignalViewControllerDelegate {
    func activateDetachButton()
    func deactivateDetachButton()
    func detachButtonConnectingStatus()
    func detachButtonConnectedStatus()
}

class BLESignalViewController: UIViewController, PayPalPaymentDelegate, BLESignalViewControllerDelegate {
    
    var QRValue : String?
    let model = Model.sharedInstance
    let payPalConfig = PayPalConfiguration()
    let clientIDs = [PayPalEnvironmentSandbox : "ATLorItFFcLMhqv28SBRJwVCAv3xfxOWmLvHN5pGq2n9E2U-LUPwsN646ba8gtELfh4E6dmKK06aN1j0"]
    var environment:String = PayPalEnvironmentSandbox {
        willSet(newEnvironment) {
            if (newEnvironment != environment) {
                PayPalMobile.initializeWithClientIdsForEnvironments(clientIDs)
                PayPalMobile.preconnectWithEnvironment(newEnvironment)
            }
        }
    }
    
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemDescription: UILabel!
    @IBOutlet weak var payPalButton: UIButton!
    @IBOutlet weak var detachButton: UIButton!
    
    //PayPalPaymentDelegate
    func payPalPaymentDidCancel(paymentViewController: PayPalPaymentViewController) {
        paymentViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController, didCompletePayment completedPayment: PayPalPayment) {
        paymentViewController.dismissViewControllerAnimated(true, completion: { () -> Void in
            // send completed confirmation to your server
            if completedPayment.confirmation["response"]!["state"] as! String == "approved" {
                if let userID = UIDevice.currentDevice().identifierForVendor {
                    self.model.setItemPurchaserIDForIdentifier(self.QRValue!, purchaser: userID.UUIDString)
                    self.model.setItemPaymentIDForIdentifier(self.QRValue!,
                        paymentID: completedPayment.confirmation["response"]!["id"] as! String)
                    self.payPalButton.userInteractionEnabled = false
                    self.payPalButton.alpha = 0.5
                }
            }
        })
    }
    
    @IBAction func demoButtonPressed(sender: UIButton) {
        model.reset()
        payPalButton.userInteractionEnabled = true
        payPalButton.alpha = 1.0
    }
    
    @IBAction func payWithPayPalButtonPressed(sender: UIButton) {
        let payment = PayPalPayment(
            amount: model.getItemPriceForIdentifier(QRValue!)!,
            currencyCode: "USD",
            shortDescription: model.getItemNameForIdentifier(QRValue!)!,
            intent: .Sale
        )
        
        if (payment.processable) {
            let paymentViewController = PayPalPaymentViewController(payment: payment,
                                                                    configuration: payPalConfig,
                                                                    delegate: self
            )
            presentViewController(paymentViewController!, animated: true, completion: nil)
        }
        else {
            print("Payment not processable: \(payment)")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        PayPalMobile.initializeWithClientIdsForEnvironments(clientIDs)
        PayPalMobile.preconnectWithEnvironment(environment)
        
        if UIDevice.currentDevice().identifierForVendor?.UUIDString == model.getItemPurchaserIDForIdentifier(QRValue!) {
            payPalButton.userInteractionEnabled = false
            payPalButton.alpha = 0.5
        } else {
            payPalButton.userInteractionEnabled = true
            payPalButton.alpha = 1.0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = model.getItemNameForIdentifier(QRValue!)
        itemDescription.text = model.getItemDescriptionForIdentifier(QRValue!)
        itemImage.downloadedFrom(link: model.getItemPictureLinkForIdentifier(QRValue!)!, contentMode: UIViewContentMode.ScaleAspectFit)
        
        //watch Bluetooth connection
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLESignalViewController.connectionChanged(_:)), name: BLEServiceChangedStatusNotification, object: nil)
        
        //start the Bluetooth discovery process
        //btDiscoverySharedInstance.delegate = self.navigationController?.visibleViewController as? BLESignalViewControllerDelegate
        btDiscoverySharedInstance.setID(QRValue!)
        btDiscoverySharedInstance.startScanning()
        
        // Set up payPalConfig
        payPalConfig.acceptCreditCards = true
        payPalConfig.merchantName = "M E 440W Tyco Group"
        payPalConfig.merchantPrivacyPolicyURL = NSURL(string: "https://www.paypal.com/webapps/mpp/ua/privacy-full")
        payPalConfig.merchantUserAgreementURL = NSURL(string: "https://www.paypal.com/webapps/mpp/ua/useragreement-full")
        payPalConfig.languageOrLocale = NSLocale.preferredLanguages()[0]
        payPalConfig.payPalShippingAddressOption = .PayPal;
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
    
    //BLESignalViewControllerDelegate
    func activateDetachButton() {
        detachButton.userInteractionEnabled = true
        detachButton.alpha = 1.0
    }
    
    func deactivateDetachButton() {
        detachButton.userInteractionEnabled = false
        detachButton.alpha = 0.5
    }
    
    func detachButtonConnectingStatus() {
        detachButton.setTitle("Connecting...", forState: .Normal)
    }
    
    func detachButtonConnectedStatus() {
        detachButton.setTitle("Detach", forState: .Normal)
    }
    
}

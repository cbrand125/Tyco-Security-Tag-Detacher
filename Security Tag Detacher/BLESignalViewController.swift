//
//  BLESignalViewController.swift
//  Security Tag Detacher
//
//  Created by Cody Brand on 3/29/16.
//  Copyright © 2016 M E 440W Tyco Group. All rights reserved.
//

import UIKit

class BLESignalViewController: UIViewController, PayPalPaymentDelegate {
    
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
    
    //PayPalPaymentDelegate
    func payPalPaymentDidCancel(paymentViewController: PayPalPaymentViewController) {
        paymentViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController, didCompletePayment completedPayment: PayPalPayment) {
        paymentViewController.dismissViewControllerAnimated(true, completion: { () -> Void in
            // send completed confirmation to your server
            print("Here is your proof of payment:\n\n\(completedPayment.confirmation)\n\nSend this to your server for confirmation and fulfillment.")
            if completedPayment.confirmation["response"]!["state"] as! String == "approved" {
                if let userID = UIDevice.currentDevice().identifierForVendor {
                    self.model.setItemPurchaserIDForIdentifier(self.QRValue!, purchaser: userID.UUIDString)
                }
            }
        })
    }
    
    @IBAction func payWithPayPalButtonPressed(sender: UIButton) {
        let item1 = PayPalItem(name: model.getItemNameForIdentifier(QRValue!)!, withQuantity: 1, withPrice: NSDecimalNumber(string: "9.99"), withCurrency: "USD", withSku: QRValue!)
        let items = [item1]
        let total = PayPalItem.totalPriceForItems(items)
        let paymentDetails = PayPalPaymentDetails(subtotal: total, withShipping: nil, withTax: nil)
        
        let payment = PayPalPayment(amount: total, currencyCode: "USD", shortDescription: "Orange Shirt", intent: .Sale)
        payment.items = items
        payment.paymentDetails = paymentDetails
        
        if (payment.processable) {
            let paymentViewController = PayPalPaymentViewController(payment: payment, configuration: payPalConfig, delegate: self)
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
    }
    
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
    
}

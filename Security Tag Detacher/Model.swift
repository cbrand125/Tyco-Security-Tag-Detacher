//
//  Model.swift
//  Security Tag Detacher
//
//  Created by Cody Brand on 4/10/16.
//  Copyright © 2016 M E 440W Tyco Group. All rights reserved.
//

import Foundation
import UIKit

//This model will read and write to a local JSON file that will be initialized here.
//Normally, this model would instead communicate with a server holding a similar JSON file.
class Model {
    
    let filePath = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true).URLByAppendingPathComponent("items.json")
    private var allItems: [String:[String:AnyObject]]?
    
    static let sharedInstance = Model()
    
    private init() {
        var pathError : NSError?
        if filePath.checkResourceIsReachableAndReturnError(&pathError) {
            if pathError != nil {
                print(pathError)
            }
            
            let JSONData = NSData(contentsOfURL: filePath)
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(JSONData!, options: NSJSONReadingOptions()) as? [String:[String:AnyObject]]
                allItems = json
            } catch {
                print(error)
            }
        } else {
            allItems = [
                "ABC123":[
                    "Item Name":"Shirt",
                    "Item Description":"This item is a lovely orange medium size unisex T-shirt.",
                    "Item Picture Link":"http://www.customink.com/assets/site_content/products/530x542/unisex/orange-cb68a219e2b35bad123a229afac8c110.jpg",
                    "Purchaser":"Unknown",
                    "Authorization Code":10
                ]
            ]
        }
    }
    
    func getItemNameForIdentifier(identifier: String) -> String? {
        if let items = allItems {
            if let item = items[identifier] {
                if let name = item["Item Name"] {
                    if let nameString = name as? String {
                        return nameString
                    }
                }
            }
        }
        
        return nil
    }
    
    func getItemDescriptionForIdentifier(identifier: String) -> String? {
        if let items = allItems {
            if let item = items[identifier] {
                if let description = item["Item Description"] {
                    if let descriptionString = description as? String {
                        return descriptionString
                    }
                }
            }
        }
        
        return nil
    }
    
    func getItemPictureLinkForIdentifier(identifier: String) -> String? {
        if let items = allItems {
            if let item = items[identifier] {
                if let link = item["Item Picture Link"] {
                    if let linkString = link as? String {
                        return linkString
                    }
                }
            }
        }
        
        return nil
    }
    
    func getItemPurchaserIDForIdentifier(identifier: String) -> String? {
        if let items = allItems {
            if let item = items[identifier] {
                if let purchaserID = item["Purchaser"] {
                    if let purchaserIDString = purchaserID as? String {
                        return purchaserIDString
                    }
                }
            }
        }
        
        return nil
    }
    
    func setItemPurchaserIDForIdentifier(identifier: String, purchaser: String) {
        if let items = allItems {
            if items[identifier] != nil {
                allItems![identifier]!["Purchaser"] = purchaser
                saveJSON()
            }
        }
    }
    
    func getItemAuthorizationCodeForIdentifier(identifier: String) -> UInt8? {
        if let userID = UIDevice.currentDevice().identifierForVendor {
            if let purchaserID = getItemPurchaserIDForIdentifier(identifier) {
                if purchaserID == userID.UUIDString {
                    if let items = allItems {
                        if let item = items[identifier] {
                            if let authCode = item["Authorization Code"] {
                                if let authCodeNumber = authCode as? NSNumber {
                                    return authCodeNumber.unsignedCharValue
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    func saveJSON() {
        do {
            if let data = allItems {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions.PrettyPrinted)
                jsonData.writeToURL(filePath, atomically: true)
            }
        } catch let error as NSError {
            print(error)
        }
    }
    
}
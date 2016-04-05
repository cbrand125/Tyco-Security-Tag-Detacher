//
//  BTService.swift
//  Arduino_Servo
//
//  Created by Owen L Brown on 10/11/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import CoreBluetooth

/* Services & Characteristics UUIDs */
let BLEServiceUUID = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
let TXCharUUID = CBUUID(string: "713D0003-503E-4C75-BA94-3148F18D941E")
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class BTService: NSObject, CBPeripheralDelegate {
  var peripheral: CBPeripheral?
  var txCharacteristic: CBCharacteristic?
  
  init(initWithPeripheral peripheral: CBPeripheral) {
    super.init()
    
    self.peripheral = peripheral
    self.peripheral?.delegate = self
  }
  
  deinit {
    self.reset()
  }
  
  func startDiscoveringServices() {
    self.peripheral?.discoverServices([BLEServiceUUID])
  }
  
  func reset() {
    if peripheral != nil {
      peripheral = nil
    }
    
    //deallocating. Therefore, send notification
    self.sendBTServiceNotificationWithIsBluetoothConnected(false)
  }
  
  // Mark: - CBPeripheralDelegate
  func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
    let uuidsForBTService: [CBUUID] = [TXCharUUID]
    
    if (peripheral != self.peripheral) {
      //wrong Peripheral
      return
    }
    
    if (error != nil) {
      return
    }
    
    if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
      //no Services
      return
    }
    
    for service in peripheral.services! {
      if service.UUID == BLEServiceUUID {
        peripheral.discoverCharacteristics(uuidsForBTService, forService: service)
      }
    }
  }
  
  func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
    if (peripheral != self.peripheral) {
      //wrong Peripheral
      return
    }
    
    if (error != nil) {
      return
    }
    
    if let characteristics = service.characteristics {
      for characteristic in characteristics {
        if characteristic.UUID == TXCharUUID {
          self.txCharacteristic = (characteristic)
          peripheral.setNotifyValue(true, forCharacteristic: characteristic)
          
          //send notification that Bluetooth is connected and all required characteristics are discovered
          self.sendBTServiceNotificationWithIsBluetoothConnected(true)
        }
      }
    }
  }
  
  // Mark: - Private
    func writeMessage(message: UInt8) {
        //see if characteristic has been discovered before writing to it
        if let txCharacteristic = self.txCharacteristic {
            //need a mutable var to pass to writeValue function
            var messageValue = message
            let data = NSData(bytes: &messageValue, length: sizeof(UInt8))
            self.peripheral?.writeValue(data, forCharacteristic: txCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        }
    }
  
  func sendBTServiceNotificationWithIsBluetoothConnected(isBluetoothConnected: Bool) {
    let connectionDetails = ["isConnected": isBluetoothConnected]
    NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: connectionDetails)
  }
  
}
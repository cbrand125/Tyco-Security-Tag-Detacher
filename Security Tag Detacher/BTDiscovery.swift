//
//  BTDiscovery.swift
//  Arduino_Servo
//
//  Created by Owen L Brown on 9/24/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import CoreBluetooth

let btDiscoverySharedInstance = BTDiscovery();

class BTDiscovery: NSObject, CBCentralManagerDelegate {
    
    private var centralManager: CBCentralManager?
    private var peripheralBLE: CBPeripheral?
    private var identifier : String? = nil
    
    override init() {
        super.init()
        
        let centralQueue = dispatch_queue_create("com.me440w.tyco", DISPATCH_QUEUE_SERIAL)
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    func setID(id : String) {
        identifier = id
    }
    
    func startScanning() {
        if let central = centralManager {
            central.scanForPeripheralsWithServices([BLEServiceUUID], options: nil)
        }
    }
    
    func stopScanning() {
        if let central = centralManager {
            central.stopScan()
        }
    }
    
    var bleService: BTService? {
        didSet {
            if let service = self.bleService {
                service.startDiscoveringServices()
            }
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        // Be sure to retain the peripheral or it will fail during connection.
        
        // Validate peripheral information
        if ((peripheral.name == nil) || (peripheral.name == "")) {
            return
        }
        
        // If not already connected to a peripheral, then connect to this one
        if ((self.peripheralBLE == nil) || (self.peripheralBLE?.state == CBPeripheralState.Disconnected)) {
            // Retain the peripheral before trying to connect
            self.peripheralBLE = peripheral
            
            // Reset service
            self.bleService = nil
            
            // Connect to peripheral
            central.connectPeripheral(peripheral, options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
        // Create new service class
        if (peripheral == self.peripheralBLE) {
            self.bleService = BTService(initWithPeripheral: peripheral)
        }
        
        // Should only connect to expected tag with QR code ID
        if let id = identifier {
            if peripheral.name!.rangeOfString(id) == nil {
                central.cancelPeripheralConnection(peripheral)
            }
        } else {
            // Stop scanning for new devices
            central.stopScan()
        }
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        // See if it was our peripheral that disconnected
        if (peripheral == self.peripheralBLE) {
            self.bleService = nil
            self.peripheralBLE = nil
            self.identifier = nil
        }
        
        // Start scanning for new devices
        self.startScanning()
    }
    
    // MARK: - Private
    func clearDevices() {
        if let peripheral = self.peripheralBLE {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        self.bleService = nil
        self.peripheralBLE = nil
        self.identifier = nil
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch (central.state) {
        case CBCentralManagerState.PoweredOff:
            self.clearDevices()
            
        case CBCentralManagerState.Unauthorized:
            // Indicate to user that the iOS device does not support BLE.
            break
            
        case CBCentralManagerState.Unknown:
            // Wait for another event
            break
            
        case CBCentralManagerState.PoweredOn:
            self.startScanning()
            
        case CBCentralManagerState.Resetting:
            self.clearDevices()
            
        case CBCentralManagerState.Unsupported:
            break
        }
    }
    
}

//
//  ViewController.swift
//  Security Tag Detacher
//
//  Created by Guest User on 3/23/16.
//  Copyright © 2016 M E 440W Tyco Group. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var QRMessageLabel: UILabel!
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "BLESignallerSegue" {
            if let vc = segue.destinationViewController as? BLESignalViewController {
                if let message = QRMessageLabel.text {
                    vc.QRValue = message
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        QRMessageLabel.text = "No QR code is detected"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TESTING
        QRMessageLabel.text = "Shirt"
        performSegueWithIdentifier("BLESignallerSegue", sender: self)
        
        //Set up the video recording
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            let input: AnyObject! = try AVCaptureDeviceInput(device: captureDevice)
            
            captureSession = AVCaptureSession()
            captureSession?.addInput(input as! AVCaptureInput)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            view.bringSubviewToFront(QRMessageLabel)
        } catch {
            let nsError = error as NSError
            print("\(nsError).localizedDescription)")
            return
        }
        
        //Set up the QR code detection
        qrCodeFrameView = UIView()
        qrCodeFrameView?.layer.borderColor = UIColor.greenColor().CGColor
        qrCodeFrameView?.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView!)
        view.bringSubviewToFront(qrCodeFrameView!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //This method implementation from http://www.appcoda.com/qr-code-reader-swift/
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRectZero
            QRMessageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            qrCodeFrameView?.frame = barCodeObject.bounds;
            
            if metadataObj.stringValue != nil {
                QRMessageLabel.text = metadataObj.stringValue
                performSegueWithIdentifier("BLESignallerSegue", sender: self)
            }
        }
    }

}


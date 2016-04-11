//
//  UIImageView+imageFromUrl.swift
//  Security Tag Detacher
//
//  Created by Cody Brand on 4/10/16.
//  Copyright © 2016 M E 440W Tyco Group. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    
    //download an image from a URL
    func downloadedFrom(link link:String, contentMode mode: UIViewContentMode) {
        if let url = NSURL(string: link) {
            contentMode = mode
            let request = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, _, error) -> Void in
                if let data = data where error == nil, let image = UIImage(data: data) {
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        self.image = image
                    }
                } else {
                    return
                }
            })
            
            request.resume()
        }
    }
}

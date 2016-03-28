//
//  PinAnnotation.swift
//  Virtual Tourist
//
//  Created by Christopher Luc on 3/27/16.
//  Copyright © 2016 Christopher Luc. All rights reserved.
//

import Foundation
import MapKit

class PinAnnotation : MKPointAnnotation {
    
    var pin: Pin
    
    init(pin: Pin) {
        self.pin = pin
        super.init()
    }
    
}
//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Christopher Luc on 3/27/16.
//  Copyright © 2016 Christopher Luc. All rights reserved.
//

import Foundation
import MapKit
import CoreData


class Pin: NSManagedObject {
    
    @NSManaged var photos : NSOrderedSet
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
        
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Person class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the
        // dictionary. This works in the same way that it did before we started on Core Data
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        photos = NSOrderedSet()
    }
    
    var coordinate: CLLocationCoordinate2D {
        
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
        
        get {
            return CLLocationCoordinate2DMake(latitude, longitude)
        }
    }
}
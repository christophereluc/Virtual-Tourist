//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Christopher Luc on 3/27/16.
//  Copyright © 2016 Christopher Luc. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var url: String?
    @NSManaged var pin: Pin?

}

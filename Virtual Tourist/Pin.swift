//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Twelker on Jul/20/15.
//  Copyright (c) 2015 Twelker. All rights reserved.
//

import UIKit
import CoreData

@objc(Pin)

class Pin : NSManagedObject {
    
    struct Keys {
        static let Lat        = "lat"
        static let Lon        = "lon"
        static let Variance   = "variance"
        static let Photos     = "photos"
    }
    
    @NSManaged var lat        : Double
    @NSManaged var lon        : Double
    @NSManaged var variance   : Double
    @NSManaged var photos     : [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Get the entity associated with the "Pin" type.  This is an object that contains
        // the information from the Model.xcdatamodeld file.
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Pin class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the dictionary.
        lat        = dictionary[Keys.Lat]        as! Double
        lon        = dictionary[Keys.Lon]        as! Double
        variance   = dictionary[Keys.Variance]   as! Double
    }
}
//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Twelker on Jul/20/15.
//  Copyright (c) 2015 Twelker. All rights reserved.
//

import UIKit
import CoreData

@objc(Photo)

class Photo : NSManagedObject {
    
    struct Keys {
        static let PhotoTitle      = "photo_title"
        static let Image           = "image"
        static let Url_m           = "url_m"
        static let PhotoCounter    = "photoCounter"
        // Note: this is the Key on which fetchedResultsController will sort (a key is mandatory ??)
        // It took me half a day finding out that the format MUST be Name = "name" (capital - no capital).
        // Anything else than "name" leads to system failure when fetchedReultsController is created,
        // with reason "Key <any other name> not found in photo" or similar !!!!! At least this is the case 
        // in Xcode simulator, did not test on the iPhone.
    }
    
    @NSManaged var photoTitle      : String?
    @NSManaged var image           : NSData!
    @NSManaged var url_m           : String!
    @NSManaged var location        : Pin?
    @NSManaged var photoCounter    : String!
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Get the entity associated with the "Pin" type.  This is an object that contains
        // the information from the Model.xcdatamodeld file.
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Pin class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the dictionary.
        photoTitle     = dictionary[Keys.PhotoTitle]   as? String
        image          = dictionary[Keys.Image]        as! NSData
        url_m          = dictionary[Keys.Url_m]        as! String
        photoCounter   = dictionary[Keys.PhotoCounter] as! String
    }

}

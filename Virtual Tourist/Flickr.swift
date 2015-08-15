//
//  Flickr.swift
//  Virtual Tourist
//
//  Created by Twelker on Jul/20/15.
//  Copyright (c) 2015 Twelker. All rights reserved.
//

import Foundation
import CoreData

class Flickr: NSObject {
    
    // Convenience variables and general purpose functions
    
    private var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent(Flickr.Constants.FlickrAPIKeyArchive).path!
    }
    
    private var filePathVar : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent(Flickr.Constants.LatLonVarArch).path!
    }
    
    private var filePathAskConfCollRenew : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent(Flickr.Constants.AskConfCollRenewArch).path!
    }
    
    private var filePathSupportDraggingPin : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent(Flickr.Constants.SupportDraggingPin).path!
    }
    
    private var filePathPreLoadPhotos : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent(Flickr.Constants.PreLoadPhotosArch).path!
    }
    
    private var filePathNrPhotosToDownload : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent(Flickr.Constants.NrPhotosToDownloadArch).path!
    }
    
    // Retrieve Flickr API key
    func getFlickrApiKey () -> String {
        
        var flickrApiKey = ""
        
        // If we can unarchive a dictionary, we will use it to retrieve the Flickr API key
        if let archivedFlickrAPIKey = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            flickrApiKey = archivedFlickrAPIKey[Flickr.Constants.FlickrAPIKey] as! String
        }

        return flickrApiKey
    }
    
    // Archive Flickr API key
    func setFlickrApiKey (FlickrApiKey: String) {
        
        let dictionary = [
            Flickr.Constants.FlickrAPIKey       : FlickrApiKey
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)

    }
    
    // Retrieve the size of the rectangle area around the pin to search for Flickr photos
    func getVariance() -> Double {
        
        var variance = Flickr.Constants.LatLonVarianceDefault // Initiate the variance parameter to be returned to the default value
        
        if let archivedLatLonVar = NSKeyedUnarchiver.unarchiveObjectWithFile(filePathVar) as? Double {
            variance = archivedLatLonVar
        }
        
        return variance
    }
    
    func setVariance (variance: Double) {
        
        NSKeyedArchiver.archiveRootObject(variance, toFile: filePathVar)

    }
    
    func getAskConfirmationCollectionRenewal () -> Bool {
        
        if let archivedAskConfCollRenewal = NSKeyedUnarchiver.unarchiveObjectWithFile(filePathAskConfCollRenew) as? Bool {
            return archivedAskConfCollRenewal
        } else {
            return Flickr.Constants.askConfDefault
        }
    }
    
    func setAskConfirmationCollectionRenewal (askConfirmationCollectionRenewal: Bool) {
        NSKeyedArchiver.archiveRootObject(askConfirmationCollectionRenewal, toFile: filePathAskConfCollRenew)
    }
    
    func supportDraggingPin () -> Bool {
        
        if let supportDraggingPin = NSKeyedUnarchiver.unarchiveObjectWithFile(filePathSupportDraggingPin) as? Bool {
            return supportDraggingPin
        } else {
            return Flickr.Constants.supportDraggingPin
        }
    }
    
    func setSupportDraggingPin (supportDraggingPin: Bool) {
        NSKeyedArchiver.archiveRootObject(supportDraggingPin, toFile: filePathSupportDraggingPin)
    }
    
    func preLoadPhotos () -> Bool {
        
        if let preLoadPhotos = NSKeyedUnarchiver.unarchiveObjectWithFile(filePathPreLoadPhotos) as? Bool {
            return preLoadPhotos
        } else {
            return Flickr.Constants.preLoadPhotosDefault
        }
    }
    
    func setPreLoadPhotos (preLoadPhotos: Bool) {
        NSKeyedArchiver.archiveRootObject(preLoadPhotos, toFile: filePathPreLoadPhotos)
    }
    
    func nrOfPhotosToDownload () -> Int {
        
        if let nrOfPhotosToDownload = NSKeyedUnarchiver.unarchiveObjectWithFile(filePathNrPhotosToDownload) as? Int {
            return nrOfPhotosToDownload
        } else {
            return Flickr.Constants.nrPhotosToDownloadDefault
        }
    }
    
    func setNrOfPhotosToDownload (nrOfPhotosToDownload: Int) {
        NSKeyedArchiver.archiveRootObject(nrOfPhotosToDownload, toFile: filePathNrPhotosToDownload)
    }
    
    func fetchAllPins() -> [Pin] {
        let error: NSErrorPointer = nil
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        // Check for Errors
        if error != nil {
            println("Error in fetchAllPins(): \(error)")
        }
        
        // Return the results, cast to an array of Person objects
        return results as! [Pin]
    }
    
    // Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    private var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    func addEmptyPhotos (pin: Pin) {
        
        /******************************************************************************************************
        * Add empty Photos to the pin. Retrieve photos from Flickr at random.                                 *
        * When retrieved, search for an empty pin.photo and copy it in there.                                 *
        ******************************************************************************************************/
        for index in 1...Flickr().nrOfPhotosToDownload() {
            let dictionary: [String : AnyObject] = [
                Photo.Keys.Image        : NSData(),
                Photo.Keys.PhotoTitle   : "",
                Photo.Keys.Url_m        : "",
                Photo.Keys.PhotoCounter : ""
                //                Photo.Keys.PhotoCounter : String(1000 + pin.photos.count + index),
            ]
            
            // Now we create a new Photo, using the shared Context
            let newEmptyPhoto = Photo(dictionary: dictionary, context: self.sharedContext)
            
            // For sorting of photos; this will lead to the collection view not changing a lot for new photos added
            newEmptyPhoto.photoCounter = String(1000 + pin.photos.count + 1)
            
            // Through the relationship between pin and photo the following statement
            // will automatically add photo to pin's photos array as well!!
            newEmptyPhoto.location = pin
            
            // Due to these changes the NSFetchedResultsController will take care of calling the necessary functions
            // to display the empty cells with activity indicator
            
            // Save the shared context, using the convenience method in the CoreDataStackManager
            dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                CoreDataStackManager.sharedInstance().saveContext()
            })
            
        } // End of "for index in 1...Flickr().nrOfPhotosToDownload()"
        
    }
    
    func startDownloadingPhotosForPin (pin: Pin, maxNrOfFlickrPagesIn: Int, completionHandler: (maxNrOfFlickrPagesOut: Int, success: Bool, errorString: String?) -> Void) {
        
        if maxNrOfFlickrPagesIn == 0 {
            
            // Obtain the maximum number of pages from Flickr from which to randomly select photos
            FlickrDBClient().GetFlickrMaxNrOfPagesContainingPhotos(pin.lat, lon: pin.lon) { (maxPages, success, errorString) in
                if success {
                    
                    // LOAD 12 (?) PAGES FROM FLICKR
                    self.readPagesFromFlickr(pin, maxNrOfFlickrPages: maxPages) { (success, errorString) in
                        if success {
                            completionHandler(maxNrOfFlickrPagesOut: maxPages, success: true, errorString: "")
                        } else {
                            completionHandler(maxNrOfFlickrPagesOut: 0, success: false, errorString: errorString)
                        }
                    } // End of "readPagesFromFlickr"
                } else {
                    completionHandler(maxNrOfFlickrPagesOut: 0, success: false, errorString: errorString)
                }
            }
            
        } else {
            
            // Already retrieved before, apparently; skip this step
            
            // LOAD 12 (?) PAGES FROM FLICKR
            readPagesFromFlickr(pin, maxNrOfFlickrPages: maxNrOfFlickrPagesIn) { (success, errorString) in
                if success {
                    completionHandler(maxNrOfFlickrPagesOut: maxNrOfFlickrPagesIn, success: true, errorString: "")
                } else {
                    completionHandler(maxNrOfFlickrPagesOut: 0, success: false, errorString: errorString)
                }
            } // End of "readPagesFromFlickr"

        }
        
    } // End of "startDownloadingPhotosForPin"
    
    func readPagesFromFlickr (pin: Pin, maxNrOfFlickrPages: Int, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        for index in 0...(Flickr().nrOfPhotosToDownload()-1) {
            
            // Retrieve random photo from Flickr
            let randomPage = Int(arc4random_uniform(UInt32(maxNrOfFlickrPages)+1)) // The random returns 0-39 !!
            FlickrDBClient().GetFlickrRandomPhoto(pin.lat, lon: pin.lon, pageNumber: randomPage) { (imageData, photoTitle, url_m, success, errorString) in
                
                if success {
                    
                     // Search for an empty pin.photo; if not found create a new photo
                    var emptyPhotoFound = false
                    
                    if pin.photos.count > 0 {
                        
                        for index in 0...pin.photos.count-1 {
                            if pin.photos[index].image == NSData() && emptyPhotoFound == false {
                                emptyPhotoFound     = true
                                pin.photos[index].image      = imageData
                                pin.photos[index].photoTitle = photoTitle
                                pin.photos[index].url_m      = url_m
                            }
                        }
                        
                    }
                    
                    if emptyPhotoFound == false { // Create new photo
                        
                        let dictionary: [String : AnyObject] = [
                            Photo.Keys.Image        : imageData,
                            Photo.Keys.PhotoTitle   : photoTitle!,
                            Photo.Keys.Url_m        : url_m,
                            
                            // To prevent sorting on wrong parameter leading to moving cells in the
                            // collectionView while adding new photos create an incrementing parameter
                            // "Int" is not supported by Core (??) so convert to String.
                            Photo.Keys.PhotoCounter : String(1000 + pin.photos.count + 1),
                        ]
                        
                        // Now we create a new Photo, using the shared Context
                        let newPhoto = Photo(dictionary: dictionary, context: self.sharedContext)
                        
                        // Through the relationship between pin and photo the following statement
                        // will automatically add photo to pin's photos array as well!!
                        newPhoto.location   = pin
                        
                        
                    }
                    // Save the shared context, using the convenience method in the CoreDataStackManager
                    dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                        CoreDataStackManager.sharedInstance().saveContext()
                    })
                    
                    // Return result
                    completionHandler(success: true, errorString: "")
                    
                } else {
                    completionHandler(success: false, errorString: errorString)
                }
            } // End of a-synchronous processing of "FlickrDBClient().GetFlickrRandomPhoto"
        } // End of "for-loop"
    } // End of func "readPagesFromFlickr"
    
    func removeCurrentCollectionAndSave (pin: Pin) {
        
        // Remove photos in current collection. From last to first since the photo array and the photo count are changing when delting photos.
        let savedPhotoCount = pin.photos.count
        if savedPhotoCount > 0 {
            for index in 0...savedPhotoCount-1 {
                pin.photos[savedPhotoCount - 1 - index].location = nil
            }
        }
        
        // Save the shared context, using the convenience method in the CoreDataStackManager
        dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
            CoreDataStackManager.sharedInstance().saveContext()
        })
    }
    
    func removeEmptyPhotosAndSave (pin: Pin) {
        
        // Remove empty photos in current collection. From last to first since the photo array and the photo count are changing when delting photos.
        let savedPhotoCount = pin.photos.count
        if savedPhotoCount > 0 {
            for index in 0...savedPhotoCount-1 {
                if pin.photos[savedPhotoCount - 1 - index].image == NSData() {
                    pin.photos[savedPhotoCount - 1 - index].location = nil
                }
            }
        }
        
        // Save the shared context, using the convenience method in the CoreDataStackManager
        dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
            CoreDataStackManager.sharedInstance().saveContext()
        })
    }


} // End of class "Flickr.swift"
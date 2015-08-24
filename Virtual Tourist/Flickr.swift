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
    
    // Make Flickr a singleton so that it remains in storage: it is called a thousand times and creating/deleting the class
    // in storage each time it is called generates a lot of overhead.
    static let sharedInstance = Flickr()
    private override init() {}

    
    // MARK: - Files Support
    
    let fileManager  = NSFileManager.defaultManager()
    let dirPaths     = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    
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
            NSLog ("Error in fetchAllPins(): \(error)")
        }
        
        // Return the results, cast to an array of Person objects
        return results as! [Pin]
        
    } // ========== End of "fetchAllPins" ============================================================================
    
    // Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    private var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        
    } // ========== End of "private var sharedContext" ===============================================================
    
    func downloadOnePhotoFromFlickr (pin: Pin?, maxNrOfFlickrPages: Int, completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        // Obtain an empty photo; will be added to the pin and the context will be saved to core. This happens on the main thread
        // so no need to use the "dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode" command.
        var photo = self.addEmptyPhoto(pin!)
        
            // Retrieve random photo from Flickr
            let randomPage = Int(arc4random_uniform(UInt32(maxNrOfFlickrPages)+1)) // The random returns 0-39 !!
            FlickrDBClient().GetFlickrRandomPhoto(pin!.lat, lon: pin!.lon, pageNumber: randomPage) { (imageData, photoTitle, url_m, success, errorString) in
                
                if success {
                    
                    // Save the shared context, using the convenience method in the CoreDataStackManager.
                    // Leave a-synchronous mode to update photo on the main thread which is the owner of the NSManagedObjectContext !!
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        // The pin may have been removed while waiting for the photo download e.g. when dragging a pin to a different location on the map
                      //  if let temp = pin {
                        if pin != nil {
                            
                            let imageFileName = self.fileNameFromFullFlickrPath(url_m)
                            
                            self.addImage(imageFileName, fileContents: imageData)
                            
                            
                            photo.photoTitle = photoTitle
                            photo.url_m      = imageFileName            // Save the path to the image in the photo object
                            
                            
                            // Save the photo to core
                            CoreDataStackManager.sharedInstance().saveContext()
                            
                        } else {
                        
                        } // End of "if pin != Pin() {"
                    })
                    
                    // Return result
                    completionHandler(success: true, errorString: "")
                } else {
                    completionHandler(success: false, errorString: errorString)
                }
            }
            
    } // ========== End of "downloadOnePhotoFromFlickr" ============================================================================
    
    func addEmptyPhoto (pin: Pin?) -> Photo {
        
        if pin != nil {
        
        /*******************************************************************************************************************
        * Add 1 empty Photo to the pin. Save to core on the main thread. It will be processed by fetchedResultsController. *
        *******************************************************************************************************************/
        
        let dictionary: [String : AnyObject] = [
            Photo.Keys.Image        : NSData(),
            Photo.Keys.PhotoTitle   : "",
            Photo.Keys.Url_m        : "",
            Photo.Keys.PhotoCounter : String(1000 + pin!.photos.count + 1),
        ]
        
        // Now we create a new Photo, using the shared Context
        let newEmptyPhoto = Photo(dictionary: dictionary, context: self.sharedContext)
        
        // Through the relationship between pin and photo the following statement
        // will automatically add photo to pin's photos array as well!
        newEmptyPhoto.location = pin!
        
        // Due to these changes the NSFetchedResultsController will take care of calling the necessary functions
        // to display the empty cells with activity indicator
        
        // Save the shared context, using the convenience method in the CoreDataStackManager
        CoreDataStackManager.sharedInstance().saveContext() // Should already be on the main thread
         
            return newEmptyPhoto
        } else {
            return Photo()
        }
    
    } // ========== End of "addEmptyPhoto" =======================================================================================================

    func removeCurrentCollectionAndSave(pin: Pin) {
        
        // Remove photos in current collection. From last to first since the photo array and the photo count are changing when delting photos.
        let savedPhotoCount = pin.photos.count
        if savedPhotoCount > 0 {
            for index in 0...savedPhotoCount-1 {
                
                // Remove image from the Documents Directory
                removeImage(pin.photos[savedPhotoCount - 1 - index].url_m)
                
                // and remove the photo from the pin
                pin.photos[savedPhotoCount - 1 - index].location = nil
            }
        }
        
        // Save the shared context, using the convenience method in the CoreDataStackManager
        CoreDataStackManager.sharedInstance().saveContext() // SHOULD ALREADY BE ON THE MAIN THREAD
    }
    
    func removeEmptyPhotosAndSave(pin: Pin) {
        
        // Remove empty photos in current collection. From last to first since the photo array and the photo count are changing when deleting photos.
        let savedPhotoCount = pin.photos.count
        if savedPhotoCount > 0 {
            for index in 0...savedPhotoCount-1 {
                if pin.photos[savedPhotoCount - 1 - index].url_m == "" {
                    pin.photos[savedPhotoCount - 1 - index].location = nil
                }
            }
        }
        
        // Save the shared context, using the convenience method in the CoreDataStackManager
        CoreDataStackManager.sharedInstance().saveContext() // SHOULD ALREADY BE ON THE MAIN THREAD
    }
    
    func fileNameFromFullFlickrPath (FlickrPath: String) -> String {
        var fullFlickrPath = Array(FlickrPath)
        var fileName = ""
        var stopSearchingForwardSlash = false
        for var index = (fullFlickrPath.count - 1); index >= 0; index-- {
            if fullFlickrPath[index] == "/" {
                if stopSearchingForwardSlash {
                    // Do nothing
                } else {
                    stopSearchingForwardSlash = true
                    for index2 in (index+1)...(fullFlickrPath.count-1) {
                        fileName.append(fullFlickrPath[index2])
                    }
                }
            }
        }
        return fileName
    }
    
    func createDir () {
        
        var documentsdir = dirPaths[0] as! String // The Documents Directory where to store our files
        documentsdir += "/Flickr-images"
        
        // Create Flickr-images directory to contain our downloaded images. Ignore error since it will only tell you
        // that directory already exists or a severe error occurred from which we cannot recover anyway
        fileManager.createDirectoryAtPath(documentsdir, withIntermediateDirectories: false, attributes: nil, error: nil)
    }
    
    func addImage (fileName: String, fileContents: NSData) {
        
        var documentsdir = dirPaths[0] as! String // The Documents Directory where to store our files
        documentsdir += "/Flickr-images"
        
        // Add the imagefile
        let filePath = documentsdir + "/" + fileName
        fileManager.createFileAtPath(filePath, contents: fileContents, attributes: nil)
    }
    
    func readImage (fileName: String) -> NSData? {
        
        var documentsdir = dirPaths[0] as! String // The Documents Directory where to store our files
        documentsdir += "/Flickr-images"
        
        // Read the imagefile
        let filePath = documentsdir + "/" + fileName
        
        return fileManager.contentsAtPath(filePath) // Returns nil in case of error (refer to class reference)
    }
    
    func removeImage (fileName: String) {
        
        var documentsdir = dirPaths[0] as! String // The Documents Directory where to store our files
        documentsdir += "/Flickr-images"
        
        // Remove the imagefile
        let filePath = documentsdir + "/" + fileName
        fileManager.removeItemAtPath(filePath, error: nil)
        
    }

} // End of class "Flickr.swift"
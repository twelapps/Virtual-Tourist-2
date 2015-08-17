//
//  PhotoAlbumVC.swift
//  Virtual Tourist
//
//  Created by Twelker on Jul/17/15.
//  Copyright (c) 2015 Twelker. All rights reserved.
//

import UIKit
import CoreData

class PhotoAlbumVC: UIViewController, UICollectionViewDataSource, UITextViewDelegate, NSFetchedResultsControllerDelegate {
    
    // Input parameter.
    var pin: Pin!
    
    @IBOutlet weak var errorMessage         : UITextView!
    @IBOutlet weak var newCollectionButton  : UIBarButtonItem!
    @IBOutlet weak var addToCollectionButton: UIBarButtonItem!
    @IBOutlet weak var myCollView           : UICollectionView!
    
    // Collection view cell reuse identifier
    private let reuseIdentifier = "FlickrCollectionViewCell"
    
    // Position of collectionview cells
    private let sectionInsets = UIEdgeInsets(top: -20.0, left: 10.0, bottom: 10.0, right: 10.0)
    
    // Maximum number of pages containing photos that Flickr can download in order to randomly select photos from.
    private var maxNrOfFlickrPages = 0
    
    // Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Photo.Keys.PhotoCounter, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    // Define 3 arrays for holding inserted, changed and deleted indexPaths
    private var insertIndexPaths  = [NSIndexPath]()
    private var changedIndexPaths = [NSIndexPath]()
    private var deletedIndexPaths = [NSIndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove empty photos from the pin
        Flickr.sharedInstance.removeEmptyPhotosAndSave(pin)
        
        // Initialize the (textView!) message field
        errorMessage.editable = false // do not allow edit of the error message textview field
        errorMessage.delegate = self
        
        // (De-)activate the "New Collection" and "+" buttons
        activateCollectionButtons()
        
        // Start the fetched results controller
        fetchedResultsController.performFetch(nil)
        
        // Set the delegate to this view controller
        fetchedResultsController.delegate = self
        
        // As first step, obtain the maximumber of Flickr pages from which we can randomly choose photos
        FlickrDBClient().GetFlickrMaxNrOfPagesContainingPhotos(pin.lat, lon: pin.lon) { (maxPages, success, errorString) in
            
            // Leave a-synchronous mode to read pin on the main thread which is the owner of the NSManagedObjectContext !!
            dispatch_async(dispatch_get_main_queue(), {
            
            if success {
                
                self.maxNrOfFlickrPages = maxPages
                
                // If no pin-associated photos available yet, load photos from Flickr
                if self.pin.photos.isEmpty {
                    
                    if self.retrievePhotos() {
                        // One or more photos could not be dowloaded, reload the screen to activate New Collection and "+" buttons
                        dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                            self.myCollView.reloadData()
                        }) //end of dispatch
                    }
                    
                } else {
                    // (De-)activate the "New Collection" and "+" buttons. Processing of new photos can still be going on after pin creation.
                    self.activateCollectionButtons()
                }
            } else {
                // Maybe we want to see the Collection of photos off-line. Only display error if there are no pin-associated photos yet.
                if self.pin.photos.isEmpty {
                    dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                        self.throwMessage(errorString!)
                    }) //end of dispatch
                } else {
                    // We want to see the Collection of photos off-line
                    // De-activate the "New Collection" and "+" buttons since we cannot perform these operations while off-line
                    self.newCollectionButton.enabled   = false
                    self.addToCollectionButton.enabled = false
                }
            }
                
            }) // End of dispatch_async
            
        } // End of "FlickrDBClient().GetFlickrMaxNrOfPagesContainingPhotos"
        
    } // ========== End of "viewDidLoad" =======================================================================================================
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        errorMessage.alpha = 0                                    // Do not display error message field
        errorMessage.text  = Flickr.Constants.msgEmptyMsg         // Initiate error message field
        
    } // ========== End of "viewWillAppear" =======================================================================================================
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        return sectionInfo.numberOfObjects
    } // ========== End of "collectionView.numberOfItemsInSection" ============================================================================

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
        // Pin associated photos array now managed by NSFetchedResultsController
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? FlickrCollectionViewCell
        
        if cell != nil {
    
            // Init cell
            cell!.flickrImageView.image = UIImage()
            cell!.activityIndicatorView.startAnimating()
            
            if photo.url_m != "" {
                // Retrieve the image from the Documents Directory
                let tempImage = Flickr.sharedInstance.readImage(photo.url_m)
                if tempImage != nil {
                    cell!.flickrImageView?.image = UIImage(data: tempImage!)
                    cell!.activityIndicatorView.stopAnimating()
                }
                
            }
            
        } // End of "if cell != nil {"
        
        activateCollectionButtons()
        
        return cell!
        
    } // ========== End of "collectionView.cellForItemAtIndexPath" ===============================================================================
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // Just process if there is an image in the collection item (otherwise it might just be the activity indicator) and
        // if the "new collection" button is enabled - otherwise the system is processing new photos
        if (pin.photos[indexPath.row].url_m != "") && newCollectionButton.enabled {
            
            // Deselect the selected entry otherwise the background of the selected entry remains grey
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            
            // Next viewcontroller is the PhotoDetailViewController
            let detailController = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoVC")! as! PhotoVC
            
            // Set the properties on the PhotoVC         
            detailController.photo    = pin.photos[indexPath.row]
            
            // Push it on the navigation stack
            self.navigationController!.pushViewController(detailController, animated: true)
            
        } else { /* Do nothing */ }
        
    } // ========== End of "collectionView.didSelectItemAtIndexPath" ===============================================================================

    /* FOR DEBUG ******************************************/
    func currentTimeMillis() -> Int64{
        var nowDouble = NSDate().timeIntervalSince1970
        return Int64(nowDouble*1000)
    }
    /* END DEBUG ******************************************/
    
    // MARK: - Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        // Initialize the arrays that will be used to store new, deleted and changed photos represented by their respective indexPath's
        insertIndexPaths  = [NSIndexPath]()
        changedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        
    } // ========== End of "controllerWillChangeContent" ===============================================================================
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Insert: insertIndexPaths.append(newIndexPath!)
            case .Delete: deletedIndexPaths.append(indexPath!)
            case .Update: changedIndexPaths.append(indexPath!)
            case .Move:
                deletedIndexPaths.append(indexPath!)
                insertIndexPaths.append(newIndexPath!)
            default: return
            }
    } // ========== End of "controller.didChangeObject" ===============================================================================
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        // Perform updates in batchmode
        myCollView.performBatchUpdates({() -> Void in
           
            for indexPath in self.insertIndexPaths {
                self.myCollView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.myCollView.deleteItemsAtIndexPaths([indexPath])
            }
            
            // Reload cells in order to get activity indicator or image displayed
            self.myCollView.reloadItemsAtIndexPaths(self.changedIndexPaths)
            
            }, completion: nil)
        
    } // ========== End of "controller.didChangeContent" ===============================================================================
    
    func retrievePhotos () -> Bool {
        
        // Error count. We should not bother about 1 or 2 errors but we should throw a message if no photos can be sownloaded at all.
        var errorWhileRetrievingPhotos = 0
        
        // De-activate "New Collection" and "Add to Collection" ("+") buttons
        self.newCollectionButton.enabled   = false
        self.addToCollectionButton.enabled = false
        
        for index in 0...(Flickr.sharedInstance.nrOfPhotosToDownload()-1) {
            
            // Retrieve 1 photo from Flickr
            Flickr.sharedInstance.downloadOnePhotoFromFlickr(self.pin, maxNrOfFlickrPages: self.maxNrOfFlickrPages) { (success, errorString) in
                if success {
                    // Proceed
                } else {
                    // Bad luck, increase error count.
                    errorWhileRetrievingPhotos += 1
                }
            }
        }
        
        if errorWhileRetrievingPhotos == Flickr.sharedInstance.nrOfPhotosToDownload() {
            // Throw error message
            dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                self.throwMessage(Flickr.Constants.msgNoPhotosFound2)
            }) //end of dispatch
            return false // Error
        } else {
            if errorWhileRetrievingPhotos > 0 {
                // Reload needed otherwise the "New Collection" and "Add to current collection" buttons remain de-activated
                return true
            } else {
                return false
            }
        }
        
    } // ========== End of "retrievePhotos" ===============================================================================
    
    func activateCollectionButtons() {
    
        // If all photos supplied, activate "new collection" and "add to collection" buttons
        var allPhotosSupplied = true
        for photo in pin.photos {
            if photo.url_m == "" {
                allPhotosSupplied = false
            }
        }
        if allPhotosSupplied {
            newCollectionButton.enabled   = true
            addToCollectionButton.enabled = true
        } else {
            newCollectionButton.enabled   = false
            addToCollectionButton.enabled = false
        }
    } // ========== End of "activateCollectionButtons" ===============================================================================
    
    @IBAction func newCollection(sender: UIBarButtonItem) {
        
        // First ask confirmation (default, unless overwritten in Setup)
        if Flickr.sharedInstance.getAskConfirmationCollectionRenewal() {
            
            // Display pop-up
            var alert = UIAlertController(title: "Deleting previous collection", message: "Are you sure??", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { action in
                
                Flickr.sharedInstance.removeCurrentCollectionAndSave(self.pin)
                
                if self.retrievePhotos() {
                    // One or more photos could not be dowloaded, reload the screen to activate New Collection and "+" buttons
                    dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                        self.myCollView.reloadData()
                    }) //end of dispatch
                }
                
            }))
            
            self.presentViewController(alert, animated: true, completion: nil)
            
        } // End of "askConf = True
        else
        {
            Flickr.sharedInstance.removeCurrentCollectionAndSave(pin)
            
            if self.retrievePhotos() {
                // One or more photos could not be dowloaded, reload the screen to activate New Collection and "+" buttons
                dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                    self.myCollView.reloadData()
                }) //end of dispatch
            }
        }
    } // ========== End of "newCollection" ===============================================================================
    
    @IBAction func addToCurrCollection(sender: UIBarButtonItem) {
        
        // De-activate "new collection" and "add to current collection" buttons
        newCollectionButton.enabled   = false
        addToCollectionButton.enabled = false
        
        // First remove empty photos
        Flickr.sharedInstance.removeEmptyPhotosAndSave(pin)
            
        if self.retrievePhotos() {
            // One or more photos could not be dowloaded, reload the screen to activate New Collection and "+" buttons
            dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                self.myCollView.reloadData()
            }) //end of dispatch
        }
        
        dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
            // Reload and scroll to bottom
            self.scrollToLastItem()
        })

    } // ========== End of "addToCurrCollection" ===============================================================================
    
    func throwMessage (message: String) {
        view.endEditing(true)         // Always end editing first
        errorMessage.alpha = 1        // Display message field
        errorMessage.text  = message
        
        // De-activate the "New Collection" and "+" buttons
        newCollectionButton.enabled   = false
        addToCollectionButton.enabled = false
        
        // Remove empty photos
        Flickr.sharedInstance.removeEmptyPhotosAndSave(pin)
    }
    
    func scrollToLastItem () {
        let indexPath = NSIndexPath(forRow: pin.photos.count - 1, inSection: 0)
        self.myCollView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
    }

} // ========== End of End of class "PhotoAlbumVC" ===============================================================================

extension PhotoAlbumVC : UICollectionViewDelegateFlowLayout {
    
// Layout the collection view

    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

            // Determine screensize
            let screenSize: CGRect = UIScreen.mainScreen().bounds
            let screenWidth = screenSize.width
            let screenHeight = screenSize.height
            

            var width = (screenWidth-40)/3
            if width < 80 { width = 80 }
            var heigth = (screenHeight-60-50-30)/4
            if heigth < 80 { heigth = 80 }
            
            return CGSize(width: width, height: heigth)
    }

    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            return sectionInsets
    }

}

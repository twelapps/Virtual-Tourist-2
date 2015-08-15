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
    
    @IBOutlet weak var errorMessage: UITextView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var addToCollectionButton: UIBarButtonItem!
    @IBOutlet weak var myCollView  : UICollectionView!
    
    // Collection view cell reuse identifier
    private let reuseIdentifier = "FlickrCollectionViewCell"
    
    // Position of collectionview cells
    private let sectionInsets = UIEdgeInsets(top: -20.0, left: 10.0, bottom: 10.0, right: 10.0)
    
    private var maxNrOfFlickrPages      = 0
    private var success                 = true
    private var error                   = ""
    private var scrollToBottom          = false
    
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
    var insertIndexPaths  = [NSIndexPath]()
    var changedIndexPaths = [NSIndexPath]()
    var deletedIndexPaths = [NSIndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FIX001: remove empty photos (may be a left-over of pre-fetching photos while creating the pin, with a bad Internet connection)
        Flickr().removeEmptyPhotosAndSave(pin)
        
        // Initialize the (textView!) message field
        errorMessage.editable         = false // do not allow edit of the error message textview field
        errorMessage.delegate         = self
        
        // (De-)activate the "New Collection" and "+" buttons
        activateCollectionButtons()
        
        // Start the fetched results controller
        fetchedResultsController.performFetch(nil)
        
        // Set the delegate to this view controller
        fetchedResultsController.delegate = self

        // If no pin-associated photos available yet, load photos from Flickr
        if pin.photos.isEmpty {
            
            // De-activate "New Collection" and "Add to Collection" ("+") buttons
            newCollectionButton.enabled   = false
            addToCollectionButton.enabled = false

            // As first step add 12 (?) empty photos to the collectionView (for displaying an activity indicator)
            Flickr().addEmptyPhotos(pin)
            
            // Retrieve 12 (?) photos from Flickr
            Flickr().startDownloadingPhotosForPin (self.pin, maxNrOfFlickrPagesIn: self.maxNrOfFlickrPages) { (maxNrOfFlickrPagesOut, success, errorString) in
                if success {
                    self.maxNrOfFlickrPages = maxNrOfFlickrPagesOut
                } else {
                    // Bad luck, throw message
                    dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                        self.throwMessage(errorString!)
                    }) //end of dispatch
                }
            }
        } else {
            // (De-)activate the "New Collection" and "+" buttons. Processing of new photos can still be going on after pin creation.
            activateCollectionButtons()
        }
        
    } // ========== End of "viewDidLoad" =======================================================================================================
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        errorMessage.alpha = 0                                    // Do not display error message field
        errorMessage.text  = Flickr.Constants.msgEmptyMsg         // Initiate error message field
        
    } // ========== End of "viewWillAppear" ====================================================================================================
    
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
        
            if photo.image != NSData() {
                cell!.flickrImageView?.image = UIImage(data: photo.image)
            }
            
            // Note: requeting reload of the cell on the main thread here causes a loop! Don't try that again.

        } // End of "if cell != nil {"
        
        activateCollectionButtons()
        
        return cell!
        
    } // ========== End of "collectionView.cellForItemAtIndexPath" ===============================================================================
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // Just process if there is an image in the collection item (otherwise it might just be the activity indicator) and
        // if the "new collection" button is enabled - otherwise the system is processing new photos
        if (pin.photos[indexPath.row].image != NSData()) && newCollectionButton.enabled {
            
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

    /* For DEBUG: timestamp ******************************************/
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
    
    func activateCollectionButtons() {
    
        // If all photos supplied, activate "new collection" and "add to collection" buttons
        var allPhotosSupplied = true
        for photo in pin.photos {
            if photo.image == NSData() {
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
        if Flickr().getAskConfirmationCollectionRenewal() {
            
            // Display pop-up
            var alert = UIAlertController(title: "Deleting previous collection", message: "Are you sure??", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { action in
                
                // De-activate "new collection" and "add to current collection" buttons
                self.newCollectionButton.enabled   = false
                self.addToCollectionButton.enabled = false
                
                // Remove current collection
                Flickr().removeCurrentCollectionAndSave(self.pin)
                
                // As first step add 12 (?) empty photos to the collectionView
                Flickr().addEmptyPhotos(self.pin)
                
                // Do not reload / scroll to bottom but retrieve 12 (?) photos from Flickr
                Flickr().startDownloadingPhotosForPin (self.pin, maxNrOfFlickrPagesIn: self.maxNrOfFlickrPages) { (maxNrOfFlickrPagesOut, success, errorString) in
                    if success {
                        self.maxNrOfFlickrPages = maxNrOfFlickrPagesOut
                    } else {
                        // Bad luck, throw message
                        dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                            self.throwMessage(errorString!)
                        }) //end of dispatch
                    }
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            
        } // End of "askConf = True
        else
        {
            // De-activate "new collection" and "add to current collection" buttons
            newCollectionButton.enabled   = false
            addToCollectionButton.enabled = false
            
            // Remove current collection
            Flickr().removeCurrentCollectionAndSave(pin)
            
            // As first step add 12 (?) empty photos to the collectionView
            Flickr().addEmptyPhotos(pin)
            
            // Do not reload / scroll to bottom but retrieve 12 (?) photos from Flickr
            Flickr().startDownloadingPhotosForPin (pin, maxNrOfFlickrPagesIn: maxNrOfFlickrPages) { (maxNrOfFlickrPagesOut, success, errorString) in
                if success {
                    self.maxNrOfFlickrPages = maxNrOfFlickrPagesOut
                } else {
                    // Bad luck, throw message
                    dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                        self.throwMessage(errorString!)
                    }) //end of dispatch
                }
            }
        }
    } // ========== End of "newCollection" ===============================================================================
    
    
    @IBAction func addToCurrCollection(sender: UIBarButtonItem) {
        
        // De-activate "new collection" and "add to current collection" buttons
        newCollectionButton.enabled   = false
        addToCollectionButton.enabled = false
        
        scrollToBottom                = true
        
        // First remove empty photos
        Flickr().removeEmptyPhotosAndSave(pin)
        
        // As first step add 12 (?) empty photos to the collectionView
        Flickr().addEmptyPhotos(pin)
        
        // Wait a second before reloading the collection view otherwise we get system crash due to scroll to invalid indexPath
        // System needs some time to handle adding empty photos
        let seconds = 1.0
        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        var dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            
            // Reload and scroll to bottom
            self.myCollView.reloadData()
            self.scrollToLastItem()
            
            // Retrieve 12 (?) photos from Flickr
            Flickr().startDownloadingPhotosForPin (self.pin, maxNrOfFlickrPagesIn: self.maxNrOfFlickrPages) { (maxNrOfFlickrPagesOut, success, errorString) in
                if success {
                    self.maxNrOfFlickrPages = maxNrOfFlickrPagesOut
                } else {
                    // Bad luck, throw message
                    dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                        self.throwMessage(errorString!)
                    }) //end of dispatch
                }
            }
            
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
        Flickr().removeEmptyPhotosAndSave(pin)
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

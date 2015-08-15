//
//  PhotoVC.swift
//  Virtual Tourist
//
//  Created by Twelker on Jul/27/15.
//  Copyright (c) 2015 Twelker. All rights reserved.
//

import UIKit
import CoreData

class PhotoVC: UIViewController {
    
    // Input parameters.
    var photo: Photo!
    
    @IBOutlet weak var photoImage : UIImageView!
    @IBOutlet weak var photoInfo  : UITextView!
    
    // Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // // Create the button for removing the photo.
        var removePhotoButton = UIBarButtonItem(title: "Remove photo",
                                                style: .Plain,
                                               target: self,
                                               action: "removePhotoSelected")
        
        self.navigationItem.setRightBarButtonItem(removePhotoButton, animated: true)
        
        photoInfo.editable = false                       // Do not allow editing of the photo info field
        photoInfo.scrollRangeToVisible(NSMakeRange(0,0)) // Let beginning of text start at upper left corner of text view
        
        // Add photo image & photo description to the view and display the view
        photoImage.image = UIImage(data: photo.image)
        
        photoInfo.text = "" // Initialize
        if photo.photoTitle != "" {
            photoInfo.text = photo.photoTitle
        }
    } // End of viewDidLoad
    
    func removePhotoSelected() {
        
        // Remove photo and save the remainder to core
        photo.location = nil
        
        // Finally we save the shared context, using the convenience method in the CoreDataStackManager
        CoreDataStackManager.sharedInstance().saveContext()
        
        // Return to collection view which will be reloaded
        returnDetailItemView()
    }
    
    func returnDetailItemView() {
        if let navigationController = self.navigationController {
            navigationController.popViewControllerAnimated(true)
        }
    }

    
}
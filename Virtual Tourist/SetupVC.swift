//
//  SetupVC.swift
//  Virtual Tourist
//
//  Created by Twelker on Jul/28/15.
//  Copyright (c) 2015 Twelker. All rights reserved.
//

import Foundation

import UIKit

class SetupVC: UIViewController {
    
    @IBOutlet weak var FlickrAPIKey             : UITextView!
    @IBOutlet weak var latLonVariance           : UISlider!
    @IBOutlet weak var confirmCollectionRenewal : UISwitch!
    @IBOutlet weak var supportDraggingPinSwitch : UISwitch!
    @IBOutlet weak var nrPhotosToDownloadInput  : UITextField!
    @IBOutlet weak var preLoadPhotosLabel       : UILabel!
    @IBOutlet weak var preLoadPhotosSwitch      : UISwitch!
    
    var tapRecognizer: UITapGestureRecognizer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add button "Done" to the navigation bar
        var pinBarButtonItem = UIBarButtonItem(title: "Done",
                                               style: .Plain,
                                              target: self,
                                              action: "DoneSelected")
        self.navigationItem.setRightBarButtonItem(pinBarButtonItem, animated: true)
        
        // De-activate function to switch preloading of pins until further notice; always preload now
        preLoadPhotosLabel.enabled  = false
        preLoadPhotosLabel.alpha    = 0
        preLoadPhotosSwitch.enabled = false
        preLoadPhotosSwitch.alpha   = 0
        
        // Get Flickr API key
        if Flickr().getFlickrApiKey() != "" {
            FlickrAPIKey.text = Flickr.Constants.FlickrAPIKeyToDisplay
        } else {
            FlickrAPIKey.text = ""
        }
        
        // Get variance parameter (between 0.1 and 1 degrees)
        let getLatLonVar = Flickr().getVariance()
        latLonVariance.setValue(Float(getLatLonVar*10), animated: false)
        
        // Get confirmation parameter
        if Flickr().getAskConfirmationCollectionRenewal() {
            confirmCollectionRenewal.setOn(true, animated: true)
        } else {
            confirmCollectionRenewal.setOn(false, animated: true)
        }
        
        // Get support dragging pin parameter
        if Flickr().supportDraggingPin() {
            supportDraggingPinSwitch.setOn(true, animated: true)
        } else {
            supportDraggingPinSwitch.setOn(false, animated: true)
        }
        
        // Get pre-load photos parameter
        if Flickr().preLoadPhotos() {
            preLoadPhotosSwitch.setOn(true, animated: true)
        } else {
            preLoadPhotosSwitch.setOn(false, animated: true)
        }
        
        // Get nr of photos to download
        
        nrPhotosToDownloadInput.text = String(Flickr().nrOfPhotosToDownload())
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        tapRecognizer!.numberOfTapsRequired = 1
        
    } // End of viewDidLoad
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Remove keyboard when tapped once outside the userID or password input fields
        self.view.addGestureRecognizer(tapRecognizer!)
    }
    
    func DoneSelected() {
        
        // Archive Flickr API key
        if FlickrAPIKey.text == Flickr.Constants.FlickrAPIKeyToDisplay {
            // Do nothing, key has not changed
        } else {
            Flickr().setFlickrApiKey(FlickrAPIKey.text)
        }
        
        // Archive new variance parameter
        changeVariance()
        
        // Archive number of photos to download
        let temp = nrPhotosToDownloadInput.text.toInt()
        if temp != nil && temp >= 1  && temp <= Flickr.Constants.nrPhotosToDownloadDefault {
            Flickr().setNrOfPhotosToDownload(temp!)
        } else {
            if temp < 1 {
                Flickr().setNrOfPhotosToDownload(1)
            } else {
                Flickr().setNrOfPhotosToDownload(Flickr.Constants.nrPhotosToDownloadDefault)
            }
        }
        
        // Go to previous VC
        if let navigationController = self.navigationController {
            navigationController.popViewControllerAnimated(true)
        }
        
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    @IBAction func changeVariance() {
        
        let v: Double = Double(round(latLonVariance.value)/10) // Rounds up to int, deviding by 10 to 1 decimal
        
        Flickr().setVariance(v)
    }
    
    @IBAction func confirmCollRenewal (sender: AnyObject) {
        
        let confSwitch: Bool = confirmCollectionRenewal.on ? true : false
        
        Flickr().setAskConfirmationCollectionRenewal(confSwitch)
    }
    
    @IBAction func supportDraggingPin (sender: AnyObject) {
        
        let draggingPinSwitch: Bool = supportDraggingPinSwitch.on ? true : false
        
        Flickr().setSupportDraggingPin(draggingPinSwitch)
    }
    
    @IBAction func preLoadPhotos (sender: AnyObject) {
        
        let myPreLoadPhotosSwitch: Bool = preLoadPhotosSwitch.on ? true : false
        
        Flickr().setPreLoadPhotos(myPreLoadPhotosSwitch)
    }

}
//
//  TravelLocationsMapVC.swift
//  Virtual Tourist
//
//  Created by Twelker on Jul/16/15.
//  Copyright (c) 2015 Twelker. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapVC: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    // Save previous location in order to erase the pin after a micro movement of the user's cursor and place a new pin
    var previousLocation = MKPointAnnotation()
    
    var locCoordAnnot = MKPointAnnotation()
    
    // Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    var pins = [Pin]() // Variable string to hold the pins.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        restoreMapRegion(false) // "false" is the animation parameter.
        
        // Setup a gesture recogniser for a long press (tap and hold): for getting and placing a new pin on the map.
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture:")
        self.mapView.addGestureRecognizer(longPressGesture)
        
        // Create the button for selecting the Setup menu
        var setupBarButtonItem = UIBarButtonItem(title: "Setup",
            style: .Plain,
            target: self,
            action: "setupSelected")
        self.navigationItem.setRightBarButtonItem(setupBarButtonItem, animated: true)
        
        // Check if there is a Flickr API key; if not navigate to setup menu
        if Flickr().getFlickrApiKey() == "" {
            setupSelected()
        }
        
    } // End of viewDidLoad
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // First remove all previous pins from the mapview
        mapView.removeAnnotations(mapView.annotations)
        
        // Then fetch all pins from Core (as the contents may have been changed by other user actions)
        pins = Flickr().fetchAllPins()
        
        // Place all fetched pins on the map
        if pins.count > 0 {
            
            /* We have to create an array of pin annotations. If we use a single variable and set 
               its value in a loop every time before the pin is put on the map then the a-synchronous
               process of putting pins on a map may use a variable that is already set for the next pin. */
            var arrayOfPinAnnots    = [MKPointAnnotation]()
            var pinAnnot            = MKPointAnnotation()
            for index in 0...self.pins.count-1 { // There are "count" pins so the array runs from 0..count-1
                pinAnnot            = MKPointAnnotation()
                pinAnnot.coordinate = CLLocationCoordinate2DMake(pins[index].lat, pins[index].lon)
                pinAnnot.title      = "Select =>"
                pinAnnot.subtitle   = "for photos"
                arrayOfPinAnnots.append(pinAnnot)
            }
            
            // Now put those pins on the map.
            mapView.addAnnotations(arrayOfPinAnnots)
        }
        
    } // End of viewWillAppear

    /**
    * This is the convenience method for fetching all persistent pins.
    *
    * The method creates a "Fetch Request" and then executes the request on
    * the shared context.
    */
    
    // MARK: - Save the zoom level helpers
    
    // A convenient property
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
        
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            Flickr.Constants.latitude       : mapView.region.center.latitude,
            Flickr.Constants.longitude      : mapView.region.center.longitude,
            Flickr.Constants.latitudeDelta  : mapView.region.span.latitudeDelta,
            Flickr.Constants.longitudeDelta : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let latitude       = regionDictionary[Flickr.Constants.latitude]       as! CLLocationDegrees
            let longitude      = regionDictionary[Flickr.Constants.longitude]      as! CLLocationDegrees
            let center         = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let latitudeDelta  = regionDictionary[Flickr.Constants.latitudeDelta]  as! CLLocationDegrees
            let longitudeDelta = regionDictionary[Flickr.Constants.longitudeDelta] as! CLLocationDegrees
            let span           = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion    = MKCoordinateRegion(center: center, span: span)
            
            // And restore the previous map view
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) {
        
        if (recognizer.state == UIGestureRecognizerState.Ended)
        {
            // Note: do NOT remove the gesture recognizer as we would like to receive more tap and hold events.
            
            // Reset "previous pin" in order not to delete it when you place a second pin
            previousLocation = MKPointAnnotation()
            
            // We need to make a new pin and save it to Core
            addPinToCore(locCoordAnnot.coordinate.latitude, lon: locCoordAnnot.coordinate.longitude)
            
        } // End of "recognizer.state == UIGestureRecognizerState.Ended"
        else
        {
            // Put pin on the map. Keep on doing so until the user lifts his finger from the screen.
            
            // Here we get the CGPoint for the touch and convert it to latitude and longitude coordinates to display on the map
            let point: CGPoint = recognizer.locationInView(mapView)
            let locCoord: CLLocationCoordinate2D = mapView.convertPoint(point, toCoordinateFromView: mapView)
            
            // Then all you have to do is create the annotation and add it to the map
            
            // Fill callout on the map
            locCoordAnnot            = MKPointAnnotation() // Initiate
            locCoordAnnot.coordinate = locCoord
            locCoordAnnot.title      = "Select =>"
            locCoordAnnot.subtitle   = "for photos"
            
            // Remove previous pin (if not empty). If not done you get a "line of pins" between the position where the user began pressing
            // the screen and the position where he lifted his finger from the screen.
            if (previousLocation != MKPointAnnotation()) {
                mapView.removeAnnotation(previousLocation)
            }
            
            previousLocation = locCoordAnnot // Save new location as previous location
            
            mapView.addAnnotation(locCoordAnnot)
            
        } // End of "recognizer.state != UIGestureRecognizerState.Ended"
    }
    
    func setupSelected() {
        // Next viewcontroller is the SetupViewController
        let detailController = self.storyboard!.instantiateViewControllerWithIdentifier("SetupVC")! as! SetupVC
        
        // Push it on the nav stack
        self.navigationController!.pushViewController(detailController, animated: true)
    }

}



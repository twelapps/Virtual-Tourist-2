//
//  VirtualTouristMapView.swift
//  Virtual Tourist
//
//  Created by Twelker on Aug/5/15.
//  Copyright (c) 2015 Twelker. All rights reserved.
//

import MapKit

extension TravelLocationsMapVC: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let identifier = "pin"
        var view: MKPinAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as! UIView
        }
        view.pinColor = .Red // Red pin although red should be the default; .Green and .Purple are the other options
        view.draggable = true // So that you can drag a pin to a new location; removes the need to delete pins
        return view
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        // If "drag pin" supported (see Setup menu) 
        //   Then do nothing (call-out will be displayed and upon selecting the call-out the user will be navigated to the
        //        associated photos collection)
        //   Else navigate to accociated photos collection right away
        if Flickr.sharedInstance.supportDraggingPin() {
            // Do nothing
        } else {
            // Define input parameters for PhotoAlbumVC and navigate to it
            let lat = view.annotation.coordinate.latitude
            let lon = view.annotation.coordinate.longitude
            navToPhotoCollection(lat, longitude: lon)
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!,
        calloutAccessoryControlTapped control: UIControl!) {
            
            // Define input parameters for PhotoAlbumVC and navigate to it
            let lat = view.annotation.coordinate.latitude
            let lon = view.annotation.coordinate.longitude
            navToPhotoCollection(lat, longitude: lon)
            
    }
    
    func navToPhotoCollection(latitude: Double!, longitude: Double!) {
        if let storyboard = self.storyboard {
            var controller = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumVC") as! PhotoAlbumVC
            
            // Find selected pin in the array of pins
            for index in 0...pins.count-1 {
                if (pins[index].lat == latitude) && (pins[index].lon == longitude) {
                    controller.pin = pins[index]
                }
            }
            
            if let navigationController = self.navigationController {
                navigationController.pushViewController(controller, animated: true)
            }
        }
    }
    
    // Handle move of an existing pin to a different location: remove any photos if there are
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!,
        didChangeDragState newState: MKAnnotationViewDragState,
        fromOldState oldState: MKAnnotationViewDragState) {

            /***************************************************************************************************************************
            * As soon as a new pin is created by the user the system starts downloading photos associated with the new pin location.   *
            * If the user tries to drag and drop this pin to a new location BEFORE all photos are downloaded and properly processed    *
            * the system crashes due to inconsistencies in core. Therefore, prior to allowing drag and drop first check whether all    *
            * photos are downloaded prior to proceeding. If not display a pop-up.                                                      *
            ***************************************************************************************************************************/
            
            switch newState {
                case MKAnnotationViewDragState.Starting:
                
                    // Find corresponding pin in Core Data
                    var indexOfPinToBeRemoved = -1
                    for index in 0...pins.count-1 {
                        if  (view.annotation.coordinate.latitude    == pins[index].lat) &&
                            (view.annotation.coordinate.longitude   == pins[index].lon) {
                                
                                indexOfPinToBeRemoved = index
                        }
                    } // Pin found or pin not found in Core Data
                    
                    if indexOfPinToBeRemoved != -1 { // Pin found, now check if all photos already downloaded
                        
                        // Check if all photos are there
                        if pins[indexOfPinToBeRemoved].photos.count > 0 {
                            var allPhotosPresent = true
                            for ind in 0...pins[indexOfPinToBeRemoved].photos.count-1 {
                                if pins[indexOfPinToBeRemoved].photos[ind].url_m == "" {
                                    allPhotosPresent = false
                                }
                            }
                            if allPhotosPresent {
                                deletePinFromCore(indexOfPinToBeRemoved)
                            } else { // Pin found but not all photos present yet, disallow dragging and show alert
                                view.setDragState(MKAnnotationViewDragState.Canceling, animated: true)
                                
                                let alert = UIAlertView(title:"Oops!",message:"Can't drop and drag pin till all photos are downloaded", delegate:nil,
                                    cancelButtonTitle:"OK")
                                alert.show()
                            }
                        } else { // Should not happen. But when it happens:
                            deletePinFromCore(indexOfPinToBeRemoved)
                        }
                    } else {
                        // Should not happen: pin not found in Core Data, do nothing in Core
                    }
                
                case MKAnnotationViewDragState.Ending:
                    // New coordinates are already set !! The pin that was picked is from a different managed object context.
                    // We need to make a new pin and save it to Core.
                    addPinToCore(view.annotation.coordinate.latitude, lon: view.annotation.coordinate.longitude)
                
                default:
                    let dummy = true // One executable statement mandatory
            }
    }
    
    /**
    *  This extension comforms to the MKMapViewDelegate protocol. This allows
    *  the view controller to be notified whenever the map region changes. So
    *  that it can save the new region.
    */
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    func addPinToCore (lat: Double, lon: Double) { // "pin" is implicit input and will be appended with the new pin
        
        let dictionary: [String : AnyObject] = [
            Pin.Keys.Lat            : lat,
            Pin.Keys.Lon            : lon,
            Pin.Keys.Variance       : Flickr.sharedInstance.getVariance()
        ]
        
        // Now we create a new Pin, using the shared Context
        let draggedPinToBeAdded = Pin(dictionary: dictionary, context: sharedContext)
        
        // And add append the pin to the array as well
        self.pins.append(draggedPinToBeAdded)
        
        // Finally we save the shared context, using the convenience method in the CoreDataStackManager
        CoreDataStackManager.sharedInstance().saveContext()
        
        // Start downloading photos for this pin (if requested through set-up menu; default is: do not, it soetimes generates errors.
        // Ignore errors, this is not a user requested action, running in the background and only for efficiency purposes.
        
        if Flickr.sharedInstance.preLoadPhotos() {
        
            for index in 0...(Flickr.sharedInstance.nrOfPhotosToDownload()-1) {
                
                // Retrieve 1 photo from Flickr
                Flickr.sharedInstance.downloadOnePhotoFromFlickr(draggedPinToBeAdded, maxNrOfFlickrPages: 0) { (success, errorString) in
                    if success {
                        // Proceed
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { // Leave a-synchronous mode
                            // Remove empty photos and proceed
                            Flickr.sharedInstance.removeEmptyPhotosAndSave(draggedPinToBeAdded)
                        })
                    }
                }
            }
        
        }
    }
    
    func deletePinFromCore (index: Int) {
        let pinToBeRemoved = pins[index]
        
        pins.removeAtIndex(index)
        
        // And we save the shared context, using the convenience method in
        // the CoreDataStackManager
        sharedContext.deleteObject(pinToBeRemoved)
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
}


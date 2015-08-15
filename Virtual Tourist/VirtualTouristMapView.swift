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
        if Flickr().supportDraggingPin() {
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
            
            if (newState ==  MKAnnotationViewDragState.Starting) {

                // Remove corresponding pin info from Core
                var indexOfPinToBeRemoved = -1
                for index in 0...pins.count-1 {
                    if  (view.annotation.coordinate.latitude    == pins[index].lat) &&
                        (view.annotation.coordinate.longitude   == pins[index].lon) {
                       indexOfPinToBeRemoved = index
                    }
                }
                if indexOfPinToBeRemoved != -1 {
                    deletePinFromCore(indexOfPinToBeRemoved)
                }
            }
            
            if (newState ==  MKAnnotationViewDragState.Ending) {

                // New coordinates are already set !!
                // The pin that was picked is from a different managed object context.
                // We need to make a new pin and save it to Core
                addPinToCore(view.annotation.coordinate.latitude, lon: view.annotation.coordinate.longitude)
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
            //                Pin.Keys.PinIdent       : locCoordAnnot,
            Pin.Keys.Lat            : lat,
            Pin.Keys.Lon            : lon,
            Pin.Keys.Variance       : Flickr().getVariance()
        ]
        
        // Now we create a new Pin, using the shared Context
        let draggedPinToBeAdded = Pin(dictionary: dictionary, context: sharedContext)
        
        // And add append the pin to the array as well
        self.pins.append(draggedPinToBeAdded)
        
        // Finally we save the shared context, using the convenience method in the CoreDataStackManager
        CoreDataStackManager.sharedInstance().saveContext()
        
        // Start downloading photos for this pin (if requested through set-up menu; default is: do.
        // This is not a user requested action but a system action for efficiency and performance (better user experience) purposes. 
        // Ignore error display, just clean-up data in case of error.
        if Flickr().preLoadPhotos() {
            Flickr().addEmptyPhotos(draggedPinToBeAdded)
            Flickr().startDownloadingPhotosForPin(draggedPinToBeAdded, maxNrOfFlickrPagesIn: 0) { (maxNrOfFlickrPagesOut, success, errorString) in
                
                // In case of error remove empty photos from the pin and start fresh in the collection view controller
                if success == false {
                    Flickr().removeEmptyPhotosAndSave(draggedPinToBeAdded)
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


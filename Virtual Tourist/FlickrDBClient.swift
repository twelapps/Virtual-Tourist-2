//
//  FlickrDBClient.swift
//  Virtual Tourist
//
//  Created by Twelker on Aug/8/15.
//  Copyright (c) 2015 Twelker. All rights reserved.
//

import Foundation
import UIKit

class FlickrDBClient : NSObject {
    
    func GetFlickrMaxNrOfPagesContainingPhotos(lat: Double, lon: Double, completionHandler: (maxPages: Int, success: Bool, errorString: String?) -> Void) {
        
        // Init output parameters
//        var success     = true
//        var errorString = ""
        var maxPages    = 0
        
        /* Initialize session and url */
        let session = NSURLSession.sharedSession()
        let urlString = Flickr.Constants.BASE_URL + self.escapedParameters(methodArguments(lat, lon: lon))
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        /* Initialize task for getting data. In this step only 1 page is downloaded, in order to obtain the total nr of pages. */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if downloadError != nil { // Handle error...
                completionHandler(maxPages: maxPages, success: false, errorString: Flickr.Constants.msgCouldNotCompleteReq)
                return
            } else {
                /* Success! Parse the data */
                do {
                    if let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary {
                    
                        if let photosDictionary = parsedResult.valueForKey("photos") as? [String: AnyObject] {
                            
                            /* Flickr retrieves maximum 4000 (photos) / 100 (default nr of photos per page) / hence 40 pages
                            Build in more randomness by also randomly selecting the page to retrieve a random photo image from */
                            
                            // Determine the total number of pages
                            if let totalPages = photosDictionary["pages"] as? Int {
                                maxPages = min(totalPages,Flickr.Constants.FlickrMaxPagesDownloaded)
                                completionHandler(maxPages: maxPages, success: true, errorString: "")
                            } else {
                                completionHandler(maxPages: maxPages, success: false, errorString: Flickr.Constants.msgNoPhotosFound)
                            }
                        
                        } else {
                            completionHandler(maxPages: maxPages, success: false, errorString: Flickr.Constants.msgNoPhotosFound)
                        }
                    } else {
                        completionHandler(maxPages: maxPages, success: false, errorString: Flickr.Constants.msgNoPhotosFound)
                    }
                } /* End of DO */ catch let error as NSError {
                    completionHandler(maxPages: maxPages, success: false, errorString: error.description)
                }
            } // End of "if downloadError ..." - else branch
            
        } // End of "let task = ..."
        
        /* Resume (execute) the task */
        task.resume()
        
    } // End of "func GetFlickrMaxNrOfPagesContainingPhotos ..."
    
    func GetFlickrRandomPhoto(lat: Double, lon: Double, pageNumber: Int,
        completionHandler: (imageData: NSData, photoTitle: String?, url_m: String, success: Bool, errorString: String?) -> Void) {
        
        // Init output parameters
//        var success                = true
//        var error                  = ""
        var imageData              = NSData()
        var photoTitle             = ""
        var url_m                  = ""
        
        /* Add the page to the method's arguments */
        var withPageDictionary     = methodArguments(lat, lon: lon)
        withPageDictionary["page"] = pageNumber
        
        /* Initialize session and url */
        let session                = NSURLSession.sharedSession()
        let urlString              = Flickr.Constants.BASE_URL + escapedParameters(withPageDictionary)
        let url                    = NSURL(string: urlString)!
        let request                = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if downloadError != nil { // Handle error...
                completionHandler(imageData: imageData, photoTitle: photoTitle, url_m: url_m, success: false, errorString: Flickr.Constants.msgCouldNotCompleteReq)
                return
            } else {
                
                /* Success! Parse the data */
                do {
                    if let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary {
                    
                        if let photosDictionary = parsedResult.valueForKey("photos") as? NSDictionary {
                            
                            var totalPhotosVal = 0
                            if let totalPhotos = photosDictionary["total"] as? String {
                                totalPhotosVal = (totalPhotos as NSString).integerValue
                            }
                            
                            if totalPhotosVal > 0 {
                                
                                if let photoDictArray = photosDictionary["photo"] as? [NSDictionary] {
                                    
                                    // Pick a random index to select a random photo
                                    let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoDictArray.count)))
                                    
                                    let photoDictionary = photoDictArray[randomPhotoIndex] as NSDictionary
                                    
                                    // Pick the title of the photo (if any)
                                    if let temp = photoDictionary["title"] as? String {
                                        photoTitle = temp
                                    }
                                    
                                    // Pick the image
                                    if let imageUrlString = photoDictionary["url_m"] as? String {
                                        
                                        url_m = imageUrlString
                                        
                                        let imageURL = NSURL(string: imageUrlString)
                                        
                                        if let temp2 = NSData(contentsOfURL: imageURL!) {
                                            imageData = temp2
                                            
                                            completionHandler(imageData: imageData, photoTitle: photoTitle, url_m: url_m, success: true, errorString: "")
                                        } else {
                                            completionHandler(imageData: imageData, photoTitle: photoTitle, url_m: url_m, success: false, errorString: Flickr.Constants.msgNoPhotosFound)
                                        }
                                    } else {
                                        completionHandler(imageData: imageData, photoTitle: photoTitle, url_m: url_m, success: false, errorString: Flickr.Constants.msgNoPhotosFound)
                                    } /* of "if let imageUrlString = photoDictionary["url_m"] as? String {" */
                                } else {
                                    completionHandler(imageData: imageData, photoTitle: photoTitle, url_m: url_m, success: false, errorString: Flickr.Constants.msgNoPhotosFound)
                                }
                            } else {
                                completionHandler(imageData: imageData, photoTitle: photoTitle, url_m: url_m, success: false, errorString: Flickr.Constants.msgNoPhotosFound)
                            }
                        } else {
                            completionHandler(imageData: imageData, photoTitle: photoTitle, url_m: url_m, success: false, errorString: Flickr.Constants.msgInvalidFlickrResponse)
                        }
                    } /* End of TRY */
                } /* End of DO */ catch let error as NSError {
                    completionHandler(imageData: imageData, photoTitle: photoTitle, url_m: url_m, success: false, errorString: error.description)
                }
            }
        }
        task.resume()
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        let stringRepresentation = urlVars.joinWithSeparator("&")
//        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
        return (!urlVars.isEmpty ? "?" : "") + stringRepresentation
    }
    
    func methodArguments(lat: Double, lon: Double) -> [String : AnyObject] {
        
        // Flickr access method arguments
        let methodArgs = [
            "method"        : Flickr.Constants.METHOD_NAME,
            "api_key"       : Flickr.sharedInstance.getFlickrApiKey(),
            "extras"        : Flickr.Constants.EXTRAS,
            "bbox"          : bbox(lat, lon: lon),
            "format"        : Flickr.Constants.DATA_FORMAT,
            "nojsoncallback": Flickr.Constants.NO_JSON_CALLBACK,
            "per_page"      : Flickr.Constants.PER_PAGE
        ]
        
        return methodArgs
    }
    
    func bbox(lat: Double, lon: Double) -> NSString {
        
        let latLonVar = Flickr.sharedInstance.getVariance() // Retrieve the size of the rectangle area around the pin to search for Flickr photos
        
        let latDouble    = lat
        let lonDouble    = lon
        let minLatFloat  = latDouble - latLonVar
        let maxLatFloat  = latDouble + latLonVar
        let minLonFloat  = lonDouble - latLonVar
        let maxLonFloat  = lonDouble + latLonVar
        let minLatString = NSNumberFormatter().stringFromNumber(minLatFloat)
        let maxLatString = NSNumberFormatter().stringFromNumber(maxLatFloat)
        let minLonString = NSNumberFormatter().stringFromNumber(minLonFloat)
        let maxLonString = NSNumberFormatter().stringFromNumber(maxLonFloat)
        
        if (minLatFloat > -90) && (maxLatFloat < 90) && (minLonFloat > -180) && (maxLatFloat < 180) {
            return (minLonString! + "," + minLatString! + "," + maxLonString! + "," + maxLatString!)
        } else {
            return ""
        }
    }
    
}

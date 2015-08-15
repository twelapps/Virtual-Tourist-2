//
//  Constants.swift
//  Virtual Tourist
//
//  Created by Twelker on Jul/20/15.
//  Copyright (c) 2015 Twelker. All rights reserved.
//

import Foundation

extension Flickr {
    
    struct Constants {
        
        static let FlickrAPIKeyToDisplay     = "** We have a key **"
        static let LatLonVarianceDefault: Double = 0.5
        static let askConfDefault            = true
        static let supportDraggingPin        = false
        static let preLoadPhotosDefault      = true
        
        static let nrPhotosToDownloadDefault = 12
        
        static let BASE_URL                  = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME               = "flickr.photos.search"
        static let EXTRAS                    = "url_m"
        static let DATA_FORMAT               = "json"
        static let NO_JSON_CALLBACK          = "1"
        static let PER_PAGE                  = "100" // Default
        
        static let latitude                  = "latitude"
        static let longitude                 = "longitude"
        static let latitudeDelta             = "latitudeDelta"
        static let longitudeDelta            = "longitudeDelta"
        
        static let FlickrAPIKeyArchive       = "FlickrAPIKeyArchive"
        static let FlickrAPIKey              = "FlickrAPIKey"
        
        static let LatLonVarArch             = "LatLonVarArchive"
        
        static let AskConfCollRenewArch      = "AskConfCollRenewalArchive"
        static let SupportDraggingPin        = "SupportDraggingPin"
        static let PreLoadPhotosArch         = "PreLoadPhotosArch"
        
        static let NrPhotosToDownloadArch    = "NrPhotosToDownloadArch"
        
        static let FlickrMaxPagesDownloaded  = 40
        
        static let msgEmptyMsg               = ""
        static let msgNoPhotosFound          = "No photos found. No Internet, wrong Flickr API key, quiet place?? Check Setup."
        static let msgCouldNotCompleteReq    = "Could not retrieve photos from Flickr. Internet problem?"
        static let msgInvalidFlickrResponse  = "The response Flickr gave could not be processed."
        
    }
    
}
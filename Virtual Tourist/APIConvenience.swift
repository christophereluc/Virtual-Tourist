//
//  APIConvenience.swift
//  Virtual Tourist
//
//  Created by Christopher Luc on 3/27/16.
//  Copyright © 2016 Christopher Luc. All rights reserved.
//

import Foundation
import CoreData

extension APIClient {
    
    
    // MARK: GET Convenience Methods
    
    func getImageURLS(pin: Pin, completionHandlerForImages: (result: Bool, error: NSError?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters = [
            FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
            FlickrParameterKeys.BoundingBox: bboxString(pin.latitude, longitude: pin.longitude),
            FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
            FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
            FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
            FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback,
            FlickrParameterKeys.PerPage : FlickrParameterValues.PerPage,
            FlickrParameterKeys.Page : String(getRandomPage())
        ]
        
        /* 2. Make the request */
        taskForGETMethod(parameters) { (results, error) in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                completionHandlerForImages(result: false, error: error)
            } else {
                
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = results[FlickrResponseKeys.Status] as? String where stat == FlickrResponseValues.OKStatus else {
                    completionHandlerForImages(result: false, error: error)
                    return
                }
                
                /* GUARD: Is the "photos" key in our result? */
                guard let photosDictionary = results[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    completionHandlerForImages(result: false, error: error)
                    return
                }
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    completionHandlerForImages(result: false, error: error)
                    return
                }
                if let pages = photosDictionary[FlickrResponseKeys.Pages] as? Int {
                    self.totalPages = pages
                }
                
                if photosArray.count == 0 {
                    completionHandlerForImages(result: false, error: error)
                    return
                } else {
                    self.sharedContext.performBlockAndWait({
                        for photo in photosArray{
                            if let url = photo[FlickrResponseKeys.MediumURL] as? String, let id = photo[FlickrResponseKeys.Id] as? String {
                                
                                //...create a new Photo managed object with it...
                                let newPhoto = Photo(photoURL: url, pin: pin, id: id, context: self.sharedContext)
                                pin.photos.addObject(newPhoto)
                                
                            }
                        }
                        completionHandlerForImages(result: true, error: nil)
                    })
                }
            }
        }
    }
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        
    }
    
    var sharedContext: NSManagedObjectContext {
        
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
}
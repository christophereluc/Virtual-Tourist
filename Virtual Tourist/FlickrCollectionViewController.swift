//
//  FlickrCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Christopher Luc on 3/27/16.
//  Copyright © 2016 Christopher Luc. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class FlickrCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var map: MKMapView!
    
    var pin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        placePin(pin!)
        // Step 2: Perform the fetch
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        fetchedResultsController.delegate = self
    }
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    //Places the pin on the map
    func placePin(pin: Pin){
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
        let pinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: nil)
        map.centerCoordinate = pointAnnotation.coordinate
        map.addAnnotation(pinAnnotationView.annotation!)
        let span = MKCoordinateSpanMake(0.5, 0.5)
        let region = MKCoordinateRegion(center: pointAnnotation.coordinate, span: span)
        map.setRegion(region, animated: true)
        
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrImageViewCell", forIndexPath: indexPath) as! FlickrImageViewCell
        cell.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let image = photo.photo {
            //Image was cached locally
            cell.imageView!.image = image
        }
        else {
            //We need to download image
            cell.imageView!.image = UIImage(named: "Photo")
            APIClient.sharedInstance().taskForGETImage(photo.url, completionHandlerForImage: { (imageData, error) in
                if let image = UIImage(data: imageData!) {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        //Now make sure that the cell is still in view (so we don't update wrong cell)
                        if let cellToUpdate = collectionView.cellForItemAtIndexPath(indexPath) as? FlickrImageViewCell {
                            cellToUpdate.imageView?.image = image
                            photo.photo = image
                        }
                    })
                    
                }
                else {
                    print(error)
                }
            })
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        photo.photo = nil
        sharedContext.deleteObject(photo)
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    //
    // This is the most interesting method. Take particular note of way the that newIndexPath
    // parameter gets unwrapped and put into an array literal: [newIndexPath!]
    //
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject,
                                    atIndexPath indexPath: NSIndexPath?,
                                                forChangeType type: NSFetchedResultsChangeType,
                                                              newIndexPath: NSIndexPath?) {
        
        
        switch type {
        case .Delete:
            collectionView.deleteItemsAtIndexPaths([indexPath!])
        default:
            return
        }
            
    }
    
    func controller(controller: NSFetchedResultsController,
                    didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
                                     atIndex sectionIndex: Int,
                                             forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
           
        case .Delete:
            self.collectionView.deleteSections(NSIndexSet(index: sectionIndex))
            
        default:
            return
        }
    }
    
}
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
        
        adjustFlowLayout(self.view.frame.size)
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        setupMap()
        placePin()

        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        fetchedResultsController.delegate = self
    }
    
    func adjustFlowLayout(size: CGSize) {
        let space: CGFloat = 1.5
        let dimension:CGFloat = size.width >= size.height ? (size.width - (5 * space)) / 6.0 :  (size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
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
    func placePin(){
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
        let pinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: nil)
        map.addAnnotation(pinAnnotationView.annotation!)
    }
    
    func setupMap() {
        let span = MKCoordinateSpanMake(0.5, 0.5)
        let region = MKCoordinateRegion(center: pin.coordinate, span: span)
        map.setRegion(region, animated: true)
        map.zoomEnabled = false
        map.scrollEnabled = false
        map.userInteractionEnabled = false
        map.centerCoordinate = pin.coordinate
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo? {
            //...and return the number of items in the section...
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrImageViewCell", forIndexPath: indexPath) as! FlickrImageViewCell
        cell.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let image = photo.photo {
            //Image was cached locally
            cell.imageView!.image = image
            cell.activityIndicator.hidden = true
            cell.activityIndicator.stopAnimating()
        }
        else {
            cell.activityIndicator.hidden = false
            cell.activityIndicator.startAnimating()
            
            //We need to download image
            cell.imageView!.image = UIImage(named: "Photo")
            APIClient.sharedInstance().taskForGETImage(photo.url, completionHandlerForImage: { (imageData, error) in
                if let image = UIImage(data: imageData!) {
                    photo.photo = image
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        //Now make sure that the cell is still in view (so we don't update wrong cell)
                        if let cellToUpdate = collectionView.cellForItemAtIndexPath(indexPath) as? FlickrImageViewCell {
                            cellToUpdate.imageView?.image = image
                            cell.activityIndicator.hidden = true
                            cell.activityIndicator.stopAnimating()
                        }
                    })
                    
                }
            })
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        sharedContext.deleteObject(photo)
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    //
    // This is the most interesting method. Take particular note of way the that newIndexPath
    // parameter gets unwrapped and put into an array literal: [newIndexPath!]
    //
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject,
                    atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            
        case .Update:
            updatedIndexPaths.append(indexPath!)
            
        default:
            break
        }
    }
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths : [NSIndexPath]!
    var updatedIndexPaths : [NSIndexPath]!
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths  = [NSIndexPath]()
        updatedIndexPaths  = [NSIndexPath]()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        //Make the relevant updates to the collectionView once Core Data has finished its changes.
        collectionView.performBatchUpdates({
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    @IBAction func getNewCollection(sender: UIBarButtonItem) {
        sender.enabled = false
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        CoreDataStackManager.sharedInstance().saveContext()
        
        APIClient.sharedInstance().getImageURLS(pin) {
            success, error in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    CoreDataStackManager.sharedInstance().saveContext()
                    sender.enabled = true
                    self.collectionView.reloadData()
                })
            }
        }
    }
}
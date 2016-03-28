//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Christopher Luc on 3/26/16.
//  Copyright © 2016 Christopher Luc. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        return fetchedResultsController
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.map.delegate = self
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.addAnnotation(_:)))
        uilgr.minimumPressDuration = 0.5
        map.addGestureRecognizer(uilgr)
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        fetchedResultsController.delegate = self
        if let pins = fetchedResultsController.fetchedObjects as? [Pin] {
            addAnnotations(pins)
        }
        
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView){
        //Clear selected annotations so that we can click on this pin immediately
        view.selected = false
        mapView.selectedAnnotations.removeAll()
    
        
        
        // Similar to the method above
        if let pin = view.annotation as? PinAnnotation {
            let controller =
                storyboard!.instantiateViewControllerWithIdentifier("FlickrCollectionViewController")
                    as! FlickrCollectionViewController
            controller.pin = pin.pin
            
            self.navigationController!.pushViewController(controller, animated: true)
        }
        print("Selected")
    }
    
    func addAnnotations(pins: [Pin]) {
        for pin in pins {
            let annotation = PinAnnotation(pin: pin)
            annotation.coordinate = pin.coordinate
            map.addAnnotation(annotation)
        }
    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            //Show loading
            let activitiyViewController = displayLoading()
            
            let touchPoint = gestureRecognizer.locationInView(map)
            let newCoordinates = map.convertPoint(touchPoint, toCoordinateFromView: map)
            
            let pin = Pin(coordinate: newCoordinates, context: sharedContext)
            
            let annotation = PinAnnotation(pin: pin)
        
            annotation.coordinate = newCoordinates
            
            APIClient.sharedInstance().getImageURLS(pin) {
                (result, error) in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    //Dissmiss loading
                    activitiyViewController.dismissViewControllerAnimated(true, completion: nil)
                    if error != nil {
                        self.showAlert("Error", text: "There was an issue retrieving data")
                    }
                    else if result == false {
                        self.showAlert("Error", text: "No photos found for that location")
                    }
                    else {
                        CoreDataStackManager.sharedInstance().saveContext()
                        self.map.addAnnotation(annotation)
                    }
                })
            }
        }
    }
    
    func showAlert(title: String, text: String) {
        let alert = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func displayLoading() -> LoadingViewController {
        let activityViewController = LoadingViewController(message: "Loading...")
        presentViewController(activityViewController, animated: true, completion: nil)
        return activityViewController
    }
}


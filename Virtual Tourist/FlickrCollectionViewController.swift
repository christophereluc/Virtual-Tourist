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

class FlickrCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pin: Pin?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    
    func adjustFlowLayout(size: CGSize) {
        let space: CGFloat = 1.5
        let dimension:CGFloat = size.width >= size.height ? (size.width - (5 * space)) / 6.0 :  (size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (pin?.photos.allObjects.count)!
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrImageViewCell", forIndexPath: indexPath) as! FlickrImageViewCell
        cell.imageView!.image = UIImage(named: "Photo")
        cell.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
        let photo = pin?.photos.allObjects[indexPath.row] as? Photo
        
        if let url = photo?.url {
            APIClient.sharedInstance().taskForGETImage(url, completionHandlerForImage: { (imageData, error) in
                if let image = UIImage(data: imageData!) {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        cell.imageView!.image = image
                        if let cellToUpdate = collectionView.cellForItemAtIndexPath(indexPath) as? FlickrImageViewCell {
                            cellToUpdate.imageView?.image = image
                        }
                    })
                    
                } else {
                    print(error)
                }
            })
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath) {
        
        
    }
    
}
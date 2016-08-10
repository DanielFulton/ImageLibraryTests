//
//  ViewController.swift
//  ImageLibraryTests
//
//  Created by Daniel Fulton on 8/5/16.
//  Copyright © 2016 GLS Japan. All rights reserved.
//

import UIKit


class ViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageView: UIImageView!
    var selectedResult:SingleTestResult? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.updateModel), name: "update", object: nil)
        setupOperations(self.imageView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateModel() {
        //print("results: \(model.results)")
        NSOperationQueue.mainQueue().addOperationWithBlock { 
            self.collectionView.reloadData()
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.results.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let result:SingleTestResult = model.results[indexPath.row]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! SIngleImageTestCell
        cell.resultLabel.text = result.displayString()
        self.selectedResult = result
        return cell
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        let destinationVC = segue.destinationViewController as! PreheatingCollectionViewController
        destinationVC.result = self.selectedResult
        preparePreheatingModel()
    }
}


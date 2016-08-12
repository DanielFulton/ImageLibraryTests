//
//  SIngleImageTest.swift
//  ImageLibraryTests
//
//  Created by Daniel Fulton on 8/9/16.
//  Copyright © 2016 GLS Japan. All rights reserved.
//

import UIKit
var operations = [NSOperation]()
struct SingleTestModel {
    var results:[SingleTestResult] {
        didSet {
            results.sortInPlace { (first, second) -> Bool in
                return first.elapsedTime < second.elapsedTime
            }
            NSNotificationCenter.defaultCenter().postNotificationName("update", object: nil)
        }
        
    }
    init() {
        results = [SingleTestResult]()
    }
}
var model:SingleTestModel = SingleTestModel()
protocol SingleTestResult {
    var libraryType:ImageCacheLibrary { get }
    var libraryName:String { get }
    var elapsedTime:Double { get }
    func displayString() -> String
}

struct TestResult:SingleTestResult {
    let libraryName: String
    let elapsedTime: Double
    let libraryType: ImageCacheLibrary
    func displayString() -> String {
        return "\(libraryName)\n\(elapsedTime) seconds."
    }
}

func setupOperations(imageView:UIImageView) {
    var n = 1
    guard let url = testURL() else {
        print("url failed")
        return
    }
    while let library = ImageCacheLibrary(rawValue:n) {
        let newOp = NSBlockOperation.init(block: { 
            library.fetchImage(imageView, url: url, completion: { (result) in
                if result != nil {
                    model.results.append(result!)
                }
            })
        })
        operations.append(newOp)
        n += 1
    }
    testNextOperation()
}

func testNextOperation() {
    if let nextOp = operations.first {
        NSOperationQueue.mainQueue().addOperation(nextOp)
        operations.removeFirst()
    }
}

func testURL() -> NSURL? {
    guard let testURL = NSURL(string: "http://apod.nasa.gov/apod/image/1608/M63LRGBVermetteR.jpg") else {
        print("problem with test URL")
        return nil
    }
    return testURL
}

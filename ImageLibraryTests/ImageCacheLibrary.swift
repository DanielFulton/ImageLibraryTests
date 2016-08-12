//
//  ImageCacheLibrary.swift
//  ImageLibraryTests
//
//  Created by Daniel Fulton on 8/10/16.
//  Copyright © 2016 GLS Japan. All rights reserved.
//

import Kingfisher
import Haneke
import MapleBacon
import ImageLoader
import AlamofireImage
import Alamofire
import Nuke
let downloader = ImageDownloader()
enum ImageCacheLibrary:Int {
    case kingfisher = 1
    case haneke
    case mapleBacon
    case imageLoader
    case alamofireImage
    case nuke
    case hayabusa
    
    func fetchImage(imageView:UIImageView, url:NSURL, completion:(result:TestResult?)->Void) {
        switch self {
        case .kingfisher:
            ImageQueueSingleton.sharedInstance.addFetchOperation({ 
                let interval = CACurrentMediaTime()
                imageView.kf_setImageWithURL(url, placeholderImage: nil, optionsInfo: nil, progressBlock: nil) { (image, error, cacheType, imageURL) in
                    if (image == nil) {
                        print("kingfisher failed")
                        testNextOperation()
                        return
                    }
                    let elapsed = CACurrentMediaTime()
                    print("kingfisher finished in \(elapsed - interval) seconds")
                    completion(result: TestResult(libraryName: "kingfisher", elapsedTime: elapsed - interval, libraryType: .kingfisher))
                    testNextOperation()
                }
            })
        case .haneke:
            ImageQueueSingleton.sharedInstance.addFetchOperation({ 
                let hanekeStartTime = CACurrentMediaTime()
                imageView.hnk_setImageFromURL(url, placeholder: nil, format: nil, failure: { (failureError) in
                    print("haneke failed.")
                    testNextOperation()
                }) { (image) in
                    let hanekeFinishTime = CACurrentMediaTime()
                    print("haneke finished in \(hanekeFinishTime - hanekeStartTime) seconds")
                    completion(result: TestResult(libraryName: "haneke", elapsedTime: hanekeFinishTime - hanekeStartTime, libraryType: .haneke))
                    testNextOperation()
                }
            })
        case .mapleBacon:
            ImageQueueSingleton.sharedInstance.addFetchOperation({ 
                let mapleBaconStartTime = CACurrentMediaTime()
                imageView.setImageWithURL(url, placeholder: nil, crossFadePlaceholder: false, cacheScaled: false) { (image, error) in
                    if (image != nil) {
                        let mapleBaconFinishTime = CACurrentMediaTime()
                        print("maple bacon finished in \(mapleBaconFinishTime - mapleBaconStartTime)")
                        completion(result: TestResult(libraryName: "mapleBacon", elapsedTime: mapleBaconFinishTime - mapleBaconStartTime, libraryType: .mapleBacon))
                        //model.results.append(TestResult(libraryName: "mapleBacon", elapsedTime: mapleBaconFinishTime - mapleBaconStartTime, libraryType: .mapleBacon))
                    } else {
                        print("maple bacon failed")
                    }
                    testNextOperation()
                }
            })
        case .imageLoader:
            ImageQueueSingleton.sharedInstance.addFetchOperation({ 
                let imageLoaderStartTime = CACurrentMediaTime()
                imageView.load(url, placeholder: nil) { (url, image, error, type) in
                    let imageLoaderEndTime = CACurrentMediaTime()
                    if (image != nil) {
                        print("ImageLoader finished in \(imageLoaderEndTime - imageLoaderStartTime) seconds")
                        completion(result: TestResult(libraryName: "imageLoader", elapsedTime: imageLoaderEndTime - imageLoaderStartTime, libraryType: .imageLoader))
                    } else {
                        print("ImageLoader failed.")
                    }
                    testNextOperation()
                }
            })
        case .alamofireImage:
            ImageQueueSingleton.sharedInstance.addFetchOperation({ 
                let request = NSURLRequest(URL: url)
                let alamofireStartTime = CACurrentMediaTime()
                downloader.downloadImage(URLRequest: request) { (resp:Response) in
                    if let img = resp.result.value {
                        let alamofireEndTime = CACurrentMediaTime()
                        print("alamofire finished in \(alamofireEndTime - alamofireStartTime) seconds")
                        completion(result: TestResult(libraryName: "alamoFireImage", elapsedTime: alamofireEndTime - alamofireStartTime, libraryType: .alamofireImage))
                        imageView.image = img
                    } else {
                        print("alamofire failed")
                    }
                    testNextOperation()
                }
            })
        case .nuke:
            ImageQueueSingleton.sharedInstance.addFetchOperation({ 
                let request = ImageRequest(URL: url)
                var options = ImageViewLoadingOptions()
                let nukeStartTime = CACurrentMediaTime()
                options.handler = { view, task, response, options in
                    let nukeEndTime = CACurrentMediaTime()
                    if ((task.response?.isSuccess) != nil) {
                        print("nuke finished in \(nukeEndTime - nukeStartTime) seconds")
                        completion(result: TestResult(libraryName: "nuke", elapsedTime: nukeEndTime - nukeStartTime, libraryType: .nuke))
                    }
                    testNextOperation()
                }
                imageView.nk_setImageWith(request, options: options).resume()
            })
        case .hayabusa:
            ImageQueueSingleton.sharedInstance.addFetchOperation({ 
                if let op = self.hayabusaOp(imageView, url: url) {
                    NSOperationQueue().addOperation(op)
                }
            })
        }
    }
    func prefetchURLs(urls:[NSURL]) {
        switch self {
        case .kingfisher:
            let prefetchOp = NSBlockOperation(block: {
                let prefetcher = ImagePrefetcher.init(urls: urls, optionsInfo: nil, progressBlock: nil, completionHandler: { (skippedResources, failedResources, completedResources) in
                    
                })
                prefetcher.start()
            })
            prefetchOp.queuePriority = .High
            ImageQueueSingleton.sharedInstance.queue.addOperation(prefetchOp)
        default:
            print("this library doesnt prefetch")
        }
        
    }
    func hayabusaOp(imageView:UIImageView, url:NSURL) -> HayabusaOperation? {
        let startTime = CACurrentMediaTime()
        let op = HayabusaOperation(url: url) { (image, error) in
            let endTime = CACurrentMediaTime()
            if image != nil {
                print("hayabusa finished in \(endTime - startTime) seconds")
                model.results.append(TestResult(libraryName: "hayabusa", elapsedTime: endTime - startTime, libraryType: .hayabusa))
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    imageView.image = image
                })
            } else {
                print("hayabusa failed")
            }
        }
        return op
    }
}

class ImageQueueSingleton {
    let queue:NSOperationQueue = NSOperationQueue()
    static let sharedInstance:ImageQueueSingleton = {
        let instance = ImageQueueSingleton()
        instance.queue.maxConcurrentOperationCount = 1
        return instance
    } ()
    func addFetchOperation(closure:()->Void) {
        let op = NSBlockOperation { 
            closure()
        }
        op.queuePriority = .VeryHigh
        op.qualityOfService = .UserInitiated
        self.queue.addOperation(op)
    }
    
}
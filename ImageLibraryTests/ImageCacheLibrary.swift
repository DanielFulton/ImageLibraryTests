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
    func fetchImage(imageView:UIImageView, url:NSURL) {
        switch self {
        case .kingfisher:
            let interval = CACurrentMediaTime()
            imageView.kf_setImageWithURL(url, placeholderImage: nil, optionsInfo: nil, progressBlock: nil) { (image, error, cacheType, imageURL) in
                if (image == nil) {
                    print("kingfisher failed")
                    testNextOperation()
                    return
                }
                let elapsed = CACurrentMediaTime()
                print("kingfisher finished in \(elapsed - interval) seconds")
                model.results.append(TestResult(libraryName: "kingfisher", elapsedTime: elapsed - interval, libraryType: .kingfisher))
                testNextOperation()
            }
        case .haneke:
            let hanekeStartTime = CACurrentMediaTime()
            imageView.hnk_setImageFromURL(url, placeholder: nil, format: nil, failure: { (failureError) in
                print("haneke failed.")
                testNextOperation()
            }) { (image) in
                let hanekeFinishTime = CACurrentMediaTime()
                print("haneke finished in \(hanekeFinishTime - hanekeStartTime) seconds")
                model.results.append(TestResult(libraryName: "haneke", elapsedTime: hanekeFinishTime - hanekeStartTime, libraryType: .haneke))
                testNextOperation()
            }
        case .mapleBacon:
            let mapleBaconStartTime = CACurrentMediaTime()
            imageView.setImageWithURL(url, placeholder: nil, crossFadePlaceholder: false, cacheScaled: false) { (image, error) in
                if (image != nil) {
                    let mapleBaconFinishTime = CACurrentMediaTime()
                    print("maple bacon finished in \(mapleBaconFinishTime - mapleBaconStartTime)")
                    model.results.append(TestResult(libraryName: "mapleBacon", elapsedTime: mapleBaconFinishTime - mapleBaconStartTime, libraryType: .mapleBacon))
                } else {
                    print("maple bacon failed")
                }
                testNextOperation()
            }
        case .imageLoader:
            let imageLoaderStartTime = CACurrentMediaTime()
            imageView.load(url, placeholder: nil) { (url, image, error, type) in
                let imageLoaderEndTime = CACurrentMediaTime()
                if (image != nil) {
                    print("ImageLoader finished in \(imageLoaderEndTime - imageLoaderStartTime) seconds")
                    model.results.append(TestResult(libraryName: "imageLoader", elapsedTime: imageLoaderEndTime - imageLoaderStartTime, libraryType: .imageLoader))
                } else {
                    print("ImageLoader failed.")
                }
                testNextOperation()
            }
        case .alamofireImage:
            let request = NSURLRequest(URL: url)
            let alamofireStartTime = CACurrentMediaTime()
            downloader.downloadImage(URLRequest: request) { (resp:Response) in
                if let img = resp.result.value {
                    let alamofireEndTime = CACurrentMediaTime()
                    print("alamofire finished in \(alamofireEndTime - alamofireStartTime) seconds")
                    model.results.append(TestResult(libraryName: "alamoFireImage", elapsedTime: alamofireEndTime - alamofireStartTime, libraryType: .alamofireImage))
                    imageView.image = img
                } else {
                    print("alamofire failed")
                }
                testNextOperation()
            }
        case .nuke:
            let request = ImageRequest(URL: url)
            var options = ImageViewLoadingOptions()
            let nukeStartTime = CACurrentMediaTime()
            options.handler = { view, task, response, options in
                let nukeEndTime = CACurrentMediaTime()
                if ((task.response?.isSuccess) != nil) {
                    print("nuke finished in \(nukeEndTime - nukeStartTime) seconds")
                    model.results.append(TestResult(libraryName: "nuke", elapsedTime: nukeEndTime - nukeStartTime, libraryType: .nuke))
                }
                testNextOperation()
            }
            imageView.nk_setImageWith(request, options: options).resume()
        case .hayabusa:
            if let op = hayabusaOp(imageView, url: url) {
                NSOperationQueue().addOperation(op)
            }
        }
    }
    func prefetchURLs(urls:[NSURL]) {
        
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
    static let sharedInstance:ImageQueueSingleton = ImageQueueSingleton() {
        return ImageQueueSingleton()
    }
}
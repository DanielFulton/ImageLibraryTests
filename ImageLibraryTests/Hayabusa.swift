//
//  Hayabusa.swift
//  Hayabusa
//
//  Created by Daniel Fulton on 8/8/16.
//  Copyright © 2016 GLS Japan. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices

enum ImageIOError:ErrorType {
    case imageSourceCreationFailure
    case imageSourceNoImages
    case imageSourceIncompleteImage
    case imageOpCancelled
    case imageCreationFailure
}
typealias opCompletion = (image:UIImage?,error:ImageIOError?) -> Void
class HayabusaOperation: NSOperation {
    let requestURL:NSURL
    let completion:opCompletion
    
    init(url:NSURL, completion:opCompletion) {
        self.requestURL = url
        self.completion = completion
        super.init()
    }
    override func main() {
        if self.cancelled {
            self.completion(image: nil,error: .imageOpCancelled)
            return
        }
        let sourceDict = [kCGImageSourceShouldCache as String:true, kCGImageSourceTypeIdentifierHint as String:kUTTypeJPEG]
        guard let imageSourceRef = CGImageSourceCreateWithURL(self.requestURL, sourceDict) else {
            self.completion(image: nil, error: .imageSourceCreationFailure)
            return
        }
        guard CGImageSourceGetCount(imageSourceRef) > 0 else {
            self.completion(image: nil, error: .imageSourceNoImages)
            return
        }
        let status = CGImageSourceGetStatus(imageSourceRef)
        guard status == CGImageSourceStatus.StatusComplete else {
            self.completion(image: nil, error: .imageSourceIncompleteImage)
            return
        }
        guard let image = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, sourceDict) else {
            self.completion(image: nil, error: .imageCreationFailure)
            return
        }
        self.completion(image: UIImage(CGImage: image), error: nil)
    }
}
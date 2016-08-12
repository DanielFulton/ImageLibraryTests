//
//  PreheatingImageTestModel.swift
//  ImageLibraryTests
//
//  Created by Daniel Fulton on 8/10/16.
//  Copyright © 2016 GLS Japan. All rights reserved.
//

import UIKit

let apodBaseURL = "https://api.nasa.gov/planetary/apod"
let apiKeyParameterPrefix = "?api_key="
let dateParameterPrefix = "&date="
let apiKey = ""
var urls:[NSURL] = []
var imageLinkDict:[NSURL:NSURL] = [:]
func preparePreheatingModel() {
    urls = lastHundredDays()!
    //prefetchURLs(0...19)
}

func prefetchURLs(range:Range<Int>) {
    guard range.startIndex < urls.count && range.endIndex < urls.count else {
        return
    }
    let queue = NSOperationQueue()
    queue.maxConcurrentOperationCount = 1
    for index in range.startIndex...range.endIndex {
        let url = urls[index]
        if imageLinkDict[url] != nil {
            continue
        } else {
            let op = NSBlockOperation(block: { 
                getImageURLWithCompletion(url, completion: { (response) in
                    switch response {
                    case .success(let imageURL):
                        imageLinkDict[url] = imageURL
                    default: break
                    }
                })
            })
            op.qualityOfService = .Utility
            queue.addOperation(op)
        }
        
    }
}

func urlWithDateString(dateString:String) -> NSURL {
    return NSURL(string: apodBaseURL + apiKeyParameterPrefix + apiKey + dateParameterPrefix + dateString)!
   
}
enum PreheatingModelURLResponse {
    case success(NSURL)
    case error(ErrorType)
}
typealias imageURLCompletion = (PreheatingModelURLResponse) -> Void
func getImageURLWithCompletion(url:NSURL, completion:imageURLCompletion) {
    if let imageURL = imageLinkDict[url] {
        completion(PreheatingModelURLResponse.success(imageURL))
        return
    }
    dataForURL(url) { (response) in
        switch response {
        case .success(let data):
            JSONDictForData(data, completion: { (response) in
                switch response {
                case .success(let obj):
                    let newURL = urlForDict(obj as! NSDictionary)
                    completion(PreheatingModelURLResponse.success(newURL!))
                case .error(let newError):
                    completion(.error(newError))
                }
                
            })
        case .error(let error):
            completion(PreheatingModelURLResponse.error(error))
        }
    }
}

enum PreheatingModelDataResponse {
    case success(NSData)
    case error(ErrorType)
}
typealias dataFetchCompletion = (PreheatingModelDataResponse) -> Void

func dataForURL(url:NSURL, completion:dataFetchCompletion) { // async
    let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
        guard data != nil && error == nil else {
            print("getting data failed")
            completion(.error(error!))
            return
        }
        completion(.success(data!))
    }
    task.resume()
}

enum JSONDictResponse {
    case success(AnyObject)
    case error(ErrorType)
}
typealias jsonDictCompletion = (JSONDictResponse) -> Void
func JSONDictForData(data:NSData, completion:jsonDictCompletion) {
    do {
        let result = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        completion(.success(result))
    } catch {
        print("error making JSON dict")
        completion(.error(error))
    }
}

func urlForDict(dict:NSDictionary) -> NSURL? {
    guard let urlString = dict["url"] as! String? else {
        print("error getting url from dict")
        return nil
    }
    guard let url = NSURL(string: urlString) else {
        print("error converting url string to NSURL")
        return nil
    }
    return url
}

func lastHundredDays() -> [NSURL]? {
    let today = NSDate()
    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
    let component = NSDateComponents()
    let formatter = NSDateFormatter()
    let todayDateString = formatter.stringFromDate(today)
    var dateURLs:[NSURL] = [urlWithDateString(todayDateString)]
    formatter.dateFormat = "YYYY-MM-dd"
    for index in 1...100 {
        component.day = -index
        guard let date = calendar?.dateByAddingComponents(component, toDate: today, options: .MatchNextTimePreservingSmallerUnits) else {
            print("error adding date for index: \(index)")
            return nil
        }
        let newDateString = formatter.stringFromDate(date)
        dateURLs.append(urlWithDateString(newDateString))
    }
    return dateURLs
}


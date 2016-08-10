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
func preparePreheatingModel() {
    urls = lastHundredDays()!
}

func urlWithDateString(dateString:String) -> NSURL {
    return NSURL(string: apodBaseURL + apiKeyParameterPrefix + apiKey + dateParameterPrefix + dateString)!
   
}
enum PreheatingModelImageResponse {
    case success(UIImage)
    case error(ErrorType)
}
typealias imageFetchCompletion = (PreheatingModelImageResponse) -> Void
func getImageWithCompletion(url:NSURL, completion:imageFetchCompletion) {
    dataForURL(url) { (response) in
        switch response {
        case .success(let data):
            JSONDictForData(data)
        case .error(let error):
            completion(PreheatingModelImageResponse.error(error))
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

func JSONDictForData(data:NSData) -> AnyObject? {
    do {
        let result = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        return result
    } catch {
        print("error making JSON dict")
        return nil
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


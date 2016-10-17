//
//  MapTasks.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 9/20/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import RealmSwift


class MapTasks: NSObject {
    
    let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"
    
    var lookupAddressResults: Dictionary<NSObject, AnyObject>!
    
    var fetchedFormattedAddress: String!
    
    var fetchedAddressLongitude: Double!
    
    var fetchedAddressLatitude: Double!
    
    let baseURLDirections = "https://maps.googleapis.com/maps/api/directions/json?"
    
    var selectedRoute: Dictionary<NSObject, AnyObject>!
    var legs: Array<Dictionary<NSObject, AnyObject>>!
    var overviewPolyline: Dictionary<NSObject, AnyObject>!
    
    var originCoordinate: CLLocationCoordinate2D!
    
    var destinationCoordinate: CLLocationCoordinate2D!
    
    var originAddress: String!
    
    var destinationAddress: String!
    
    var totalDistanceInMeters: UInt = 0
    
    var totalDistance: String!
    
    var totalDurationInSeconds: UInt = 0
    
    var totalDuration: String!

    var endLat = 0.0
    var endLong = 0.0
    var originLat = 0.0
    var originLong = 0.0
 
    var startController: StartController?
    
    var aRoute : Route?
    
    init(controller: StartController) {
        startController = controller
        super.init()
    }
    
    func geocodeAddress(address: String!, withCompletionHandler completionHandler: @escaping ((_ status: String, _ success: Bool) -> Void)) {
        guard let lookupAddress = address else {
            completionHandler("No valid address.", false)
            return
        }
        var geocodeURLString = /*baseURLGeocode +*/ "address=" + lookupAddress
        geocodeURLString = geocodeURLString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        geocodeURLString = baseURLGeocode + geocodeURLString
        
        let geocodeURL = NSURL(string: geocodeURLString)
        
        DispatchQueue.main.async(execute: { () -> Void in
            let geocodingResultsData = NSData(contentsOf: geocodeURL! as URL)
            
          
            var dictionary: Dictionary<NSObject, AnyObject>
            do {
               dictionary  = try JSONSerialization.jsonObject(with: geocodingResultsData! as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<NSObject, AnyObject>
            }catch {
                completionHandler("", false)
                print("Failed to get JSON gecoding")
                return
            }
                // Get the response status.
            let status = dictionary["status" as NSObject] as! String
            guard status == "OK" else {
                completionHandler("", false)
                return
            }
            
            let allResults = dictionary["results" as NSObject] as! Array<Dictionary<NSObject, AnyObject>>
            self.lookupAddressResults = allResults[0]
            
            // Keep the most important values.
            self.fetchedFormattedAddress = self.lookupAddressResults["formatted_address" as NSObject] as! String
            let geometry = self.lookupAddressResults["geometry" as NSObject] as! Dictionary<NSObject, AnyObject>
            self.fetchedAddressLongitude = ((geometry["location" as NSObject] as! Dictionary<NSObject, AnyObject>)["lng" as NSObject] as! NSNumber).doubleValue
            self.fetchedAddressLatitude = ((geometry["location" as NSObject] as! Dictionary<NSObject, AnyObject>)["lat" as NSObject] as! NSNumber).doubleValue
            
            completionHandler(status, true)
         })
    }
    

    func getDirections(origin: String!, destination: String!, waypoints: Array<String>!, completionHandler: @escaping ((_ status: String, _ success: Bool) -> Void)) {
        
        guard let originLocation = origin else {
            completionHandler("Origin is nil", false)
            return
        }
        guard let destinationLocation = destination else {
            completionHandler("Destination is nil.", false)
            return
        }
        var directionsURLString = /*baseURLDirections + */"origin=" + originLocation + "&destination=" + destinationLocation
        CFNotificationCenterGetDarwinNotifyCenter()
        if let routeWaypoints = waypoints {
            directionsURLString += "&waypoints=optimize:true"
            
            for waypoint in routeWaypoints {
                directionsURLString += "|" + waypoint
            }
        }
        
        
        let travelModeString = "bicycling"

        directionsURLString += "&mode=" + travelModeString
        
        
        
        directionsURLString = directionsURLString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        directionsURLString = baseURLDirections + directionsURLString
        
        let directionsURL = NSURL(string: directionsURLString)
        
        DispatchQueue.main.async(execute: { () -> Void in
            let directionsData = NSData(contentsOf: directionsURL! as URL)
            
            if (Reachability.isConnectedToNetwork() == false || (directionsData == nil)) {
                self.startController?.alertMessage.showAlert(alertString: "No internet connection")
                return
            }
            var dictionary: Dictionary<NSObject, AnyObject>
            do {
               dictionary  =   try JSONSerialization.jsonObject(with: directionsData! as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<NSObject, AnyObject>
            }catch {
                self.startController?.alertMessage.showAlertWithMessageAndRestart(message: "Internal Error when downloading data. Please check internet connection.")
                return
            }
            
            let status = dictionary["status" as NSObject] as! String
            
            guard( status == "OK") else {
                self.startController?.alertMessage.showAlertWithMessageAndRestart(message: "there is no route found.")
                completionHandler(status, false)
                return
            }
            self.selectedRoute = (dictionary["routes" as NSObject] as! Array<Dictionary<NSObject, AnyObject>>)[0]
            self.overviewPolyline = self.selectedRoute["overview_polyline" as NSObject] as! Dictionary<NSObject, AnyObject>
            
            self.legs = self.selectedRoute["legs" as NSObject] as! Array<Dictionary<NSObject, AnyObject>>
            
            let startLocationDictionary = self.legs[0]["start_location" as NSObject] as! Dictionary<NSObject, AnyObject>
            self.originLat = startLocationDictionary["lat" as NSObject] as! Double
            self.originLong = startLocationDictionary["lng" as NSObject] as! Double
            
            self.originCoordinate = CLLocationCoordinate2DMake(startLocationDictionary["lat" as NSObject] as! Double, startLocationDictionary["lng" as NSObject] as! Double)
            
            let endLocationDictionary = self.legs[self.legs.count - 1]["end_location" as NSObject] as! Dictionary<NSObject, AnyObject>
            self.endLat = endLocationDictionary["lat" as NSObject] as! Double
            self.endLong = endLocationDictionary["lng" as NSObject] as! Double

            self.destinationCoordinate = CLLocationCoordinate2DMake(endLocationDictionary["lat" as NSObject] as! Double, endLocationDictionary["lng" as NSObject] as! Double)
            
            self.originAddress = self.legs[0]["start_address" as NSObject] as! String
            self.destinationAddress = self.legs[self.legs.count - 1]["end_address" as NSObject] as! String
            
            self.calculateTotalDistanceAndDuration()
            self.readLegs()
         
            completionHandler(status, true)
            })
    }
    func decodeString(encodedString:String) -> NSAttributedString?
    {
        let encodedData = encodedString.data(using: String.Encoding.utf8)!
        do {
            return try NSAttributedString(data: encodedData, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func readLegs() {
        
        let realm = try! Realm()
    
        try! realm.write {
            aRoute = Route()
            realm.add(aRoute!)
            aRoute?.startAddress = originAddress
            aRoute?.endAddress = destinationAddress
        }
    
        let dic = legs[0] ["steps" as NSObject] as! [Dictionary<NSObject,AnyObject>]
        //print(dic)
        for step in dic {
            let dir = step ["html_instructions" as NSObject] as! String
            
            let dist = step["distance" as NSObject] as! Dictionary<NSObject,AnyObject>
            let duration = step["duration" as NSObject] as! Dictionary<NSObject,AnyObject>
            let time = duration["text" as NSObject] as! String
            let distance = dist["text" as NSObject] as! String
            let attrString = decodeString(encodedString: dir)
            let oneDirection =  (attrString!.string + ".  (" + distance + ") (" + time + ")")
            let oneRouteStep = RouteStep()
            oneRouteStep.step = oneDirection

            try! realm.write {
                aRoute!.routes.append(oneRouteStep)
                realm.add(oneRouteStep)
                try! realm.commitWrite()
            }
            
        }
       
    }
    
    func calculateTotalDistanceAndDuration() {
        let legs = self.selectedRoute["legs" as NSObject] as! Array<Dictionary<NSObject, AnyObject>>
        
        totalDistanceInMeters = 0
        totalDurationInSeconds = 0
        
        for leg in legs {
            totalDistanceInMeters += (leg["distance" as NSObject] as! Dictionary<NSObject, AnyObject>)["value" as NSObject] as! UInt
            totalDurationInSeconds += (leg["duration" as NSObject] as! Dictionary<NSObject, AnyObject>)["value" as NSObject] as! UInt
        }
        
        
        let distanceInKilometers: Double = Double(totalDistanceInMeters / 1000)
        totalDistance = "Total Distance: \(distanceInKilometers) Km"
        
        
        let mins = totalDurationInSeconds / 60
        let hours = mins / 60
        let days = hours / 24
        let remainingHours = hours % 24
        let remainingMins = mins % 60
        let remainingSecs = totalDurationInSeconds % 60
        
        totalDuration = "Duration: \(days) d, \(remainingHours) h, \(remainingMins) mins, \(remainingSecs) secs"
    }
    
    
}


//
//  routeDirections.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 9/23/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import GoogleMaps
import CoreLocation

class RouteDirections: NSObject {
   
    // below vars for directions
    var mapTasks: MapTasks?
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    var markersArray: Array<GMSMarker> = []
    var waypointsArray: Array<String> = []
    var startAddressString : String!
    var endAddressString: String!
    var aRoute:Route! // for ploting existin route
    var originCoordinate: CLLocationCoordinate2D?
    var endCoordinate: CLLocationCoordinate2D?
    var startControllerInstance: StartController?
    var data = String()
    var drawExistingRoute = false
    
    init(controller: StartController){
        startControllerInstance = controller
        mapTasks = MapTasks(controller: controller)
    }
    
    func getCoordinate2D( lat: Double, long: Double) -> CLLocationCoordinate2D{
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        return coordinate
    }
 
    func drawThisRoute(){
        if(aRoute != nil){
          drawExistingRoute = true
          originCoordinate = getCoordinate2D(lat: (aRoute?.originLat)!, long: (aRoute?.originLong)!)
          endCoordinate = getCoordinate2D(lat: (aRoute?.endLat)!, long: (aRoute?.endLong)!)
        }
        
        configureMapAndMarkersForRoute()
        drawRoute()
        displayRouteInfo()
        startControllerInstance?.startButton.title = "End"
        drawExistingRoute = false
    }
    // create new route
    func createRoute(){
        
        mapTasks?.getDirections(origin: startAddressString, destination: endAddressString, waypoints: nil,  completionHandler: { (status, success) -> Void in
            if success {
                self.startControllerInstance?.activityIndicator.stopAnimating()
                self.startControllerInstance?.activityIndicator.isHidden = true
                self.drawThisRoute()
            }
            else {
                print(status)
            } })
    }
    
    
    // MARK: Custom method implementation
    
    
 
    func configureMapAndMarkersForRoute() {
        if(drawExistingRoute){
            startControllerInstance!.mapView.camera = GMSCameraPosition.camera(withTarget: originCoordinate!, zoom: 11.0)
            originMarker = GMSMarker(position: originCoordinate!)
            startControllerInstance?.bounds? =
            (startControllerInstance?.bounds?.includingCoordinate(originMarker.position))!
            
            originMarker.title = aRoute.startAddress
            destinationMarker = GMSMarker(position: endCoordinate!)
            startControllerInstance?.bounds? = 
            (startControllerInstance?.bounds?.includingCoordinate(destinationMarker.position))!
            destinationMarker.title = aRoute.endAddress
        }else {
          startControllerInstance!.mapView.camera = GMSCameraPosition.camera(withTarget: (mapTasks?.originCoordinate)!, zoom: 11.0)
            originMarker = GMSMarker(position: (self.mapTasks?.originCoordinate)!)

            startControllerInstance?.bounds? =
            (startControllerInstance?.bounds?.includingCoordinate(originMarker.position))!
            originMarker.title = self.mapTasks?.originAddress
            destinationMarker = GMSMarker(position: (self.mapTasks?.destinationCoordinate)!)
            startControllerInstance?.bounds? =
            (startControllerInstance?.bounds?.includingCoordinate(destinationMarker.position))!

            destinationMarker.title = self.mapTasks?.destinationAddress
        }
        originMarker.map = startControllerInstance!.mapView
        originMarker.icon = GMSMarker.markerImage(with: UIColor.green)
        destinationMarker.map = startControllerInstance!.mapView
        destinationMarker.icon = GMSMarker.markerImage(with: UIColor.red)
        if waypointsArray.count > 0 {
            for waypoint in waypointsArray {
                let lat: Double = (waypoint.components(separatedBy: ",")[0] as NSString).doubleValue
                let lng: Double = (waypoint.components(separatedBy:",")[1] as NSString).doubleValue
                
                let marker = GMSMarker(position: CLLocationCoordinate2DMake(lat, lng))
                marker.map = startControllerInstance!.mapView
                marker.icon = GMSMarker.markerImage(with: UIColor.purple)
                
                markersArray.append(marker)
            }
        }
        startControllerInstance?.mapView.animate(with: GMSCameraUpdate.fit((startControllerInstance?.bounds!)!
        ))
    }
    
    func drawRoute() {
        
        DispatchQueue.main.async(execute: {
        var route : String!
        if( self.aRoute != nil ){
            route = self.aRoute.polyLines
        }else {
            route = self.mapTasks?.overviewPolyline["points" as NSObject] as! String
        }
        self.startControllerInstance?.polyLines = route
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        self.routePolyline = GMSPolyline(path: path)
        self.routePolyline.map = self.startControllerInstance!.mapView
    
        })
    }
    
    func displayRouteInfo() {
        if(self.aRoute != nil){
            self.startControllerInstance!.routeInfo.text = self.aRoute.routeInfo
        }else {
            DispatchQueue.main.async(execute: {
                self.startControllerInstance!.addressLabel.isHidden = true
                self.startControllerInstance!.routeInfo.isHidden = false
                self.data =  (self.mapTasks?.totalDistance)! + "\n"
                self.data = self.data + (self.mapTasks?.totalDuration)!
                self.data = self.data + "\nStart: " + self.startAddressString + "\nEnd: " + self.endAddressString
                    
              
                self.startControllerInstance!.routeInfo.text = self.data
            
            })
        }
    }
    
    
    func clearRoute() {
        originMarker.map = nil
        destinationMarker.map = nil
        routePolyline.map = nil
        
        originMarker = nil
        destinationMarker = nil
        routePolyline = nil
        
        if markersArray.count > 0 {
            for marker in markersArray {
                marker.map = nil
            }
            
            markersArray.removeAll(keepingCapacity: false)
        }
    }
    
    
    func recreateRoute() {
        if (routePolyline) != nil {
            clearRoute()
            
            mapTasks?.getDirections(origin: mapTasks?.originAddress, destination: mapTasks?.destinationAddress, waypoints: waypointsArray, completionHandler: { (status, success) -> Void in
                
                if success {
                    self.configureMapAndMarkersForRoute()
                    self.drawRoute()
                    self.displayRouteInfo()
                }
                else {
                    print(status)
                }
            })
        }
    }

    
}

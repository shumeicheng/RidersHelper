//
//  StartController.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 8/19/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleMaps
import MapKit

class StartController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var startButton: UIBarButtonItem!    
    @IBOutlet weak var detailButton: UIBarButtonItem!
    
    @IBOutlet weak var routeInfo: UILabel!
    @IBOutlet weak var endAddress: UITextField!
    @IBOutlet weak var startAddress: UITextField!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    var geocoder: GMSGeocoder? = nil // Initialize in your constructor or viewDidLoad method.
    let locationManager = CLLocationManager()
    var routeD: RouteDirections?
    var didFindMyLocation = false
    
    var polyLines: String!
    var startCoordinate: CLLocationCoordinate2D!
    var endCoordinate: CLLocationCoordinate2D!
    var formattedAddress: String!
    var routeTableNav: UINavigationController!
    var aRoute: Route?
    var person: Person?
    var myName: String?
    var realm : Realm?
    var routeThisRoute: Route?
    var bounds:GMSCoordinateBounds?
    
    var menu = ["choose one", "existing routes", "new routes"]
    var alertMessage: Alert!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
        alertMessage = Alert(controller: self)
        routeD = RouteDirections(controller: self)
        routeD?.startControllerInstance = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.delegate = self
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.new, context: nil)
        bounds = GMSCoordinateBounds()
        startAddress.delegate = self
        endAddress.delegate = self
        
        startAddress.tag = 1
        endAddress.tag = 2
        addressLabel.numberOfLines = 0
        routeInfo.numberOfLines = 0
        enterStartStage()
        detailButton.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:  NSNotification.Name.UIKeyboardWillShow , object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillHide) , name: NSNotification.Name.UIKeyboardWillHide , object: nil)
        
        // create one if there is no person exist
        let userName = UIDevice.current.name
        myName = userName
        
        realm = try! Realm()

        let predicate = NSPredicate(format : "name = %@", userName)
        let persons = realm!.objects(Person.self).filter(predicate)
        if(persons.count == 0){
            try! realm?.write {
                person = Person()
                person?.setValue(userName, forKey: "name")
                self.realm!.add(self.person!)
            }
        }else {
           person = persons[0]
        }
        enterStartStage()

        //setup CLLocationManager
        locationManager.distanceFilter = 100.0 ; // meter
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![(NSKeyValueChangeKey.newKey as NSObject) as! NSKeyValueChangeKey] as! CLLocation
            mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 15.0)
            mapView.settings.myLocationButton = true
            
            didFindMyLocation = true
        }
    }

    private func showTablePopover ( nav : UINavigationController
        ) {
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        
        popover?.delegate = self
        popover!.sourceView = self.view
        popover!.permittedArrowDirections = .any
        DispatchQueue.main.async(execute: {
          self.present(nav, animated: true, completion: nil)
        })
    }
    
    func presentRoutesTablePopover( popoverContent : RoutesTableViewController) -> UINavigationController{
        let nav = UINavigationController(rootViewController: popoverContent)
        showTablePopover(nav: nav)
        return nav
    }
    
    func presentPopover( popoverContent: DirectionTableViewController
        ) -> UINavigationController {
        let nav =  UINavigationController(rootViewController: popoverContent)
        showTablePopover( nav: nav )
        return nav
    }
    
    func presentMenuPopover (popoverContent: MenuPickerController) -> UINavigationController{
    // why popover take over full screen swift3 the delegate function was not called is because the delegate function change!!
        let nav = UINavigationController(rootViewController: popoverContent)
    
        nav.modalPresentationStyle = .popover
        
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover!.sourceView = self.view
        popover?.sourceRect = startButton.accessibilityFrame
        popover!.permittedArrowDirections = .any
        
        popoverContent.preferredContentSize = CGSize(width: 200, height: 200)
        popoverContent.mapView = mapView
        popoverContent.startButton = startButton
        self.present(nav, animated: true, completion: nil)
        return nav
    }
    
    func checkExistingRoutes()-> Bool{
        if (person?.routes.count)! > 0 {
            return true
        } else {
            return false
        }
    }

    func enterStartStage(){
        startAddress.isHidden = true
        endAddress.isHidden = true
        routeInfo.isHidden = true
        addressLabel.isHidden = false
        let startString = addressLabel.text!
        detailButton.isEnabled = false
        startAddress.text = startString
        
        // change start button to route button
        startButton.title = "Start"
        bounds = GMSCoordinateBounds()
    }

    func enterRouteStage(){
        addressLabel.isHidden = true
        startAddress.isHidden = false
        endAddress.isHidden = false
        routeInfo.isHidden = true
        let startString = addressLabel.text!
        startAddress.text = startString
        
        // change start button to route button
        startButton.title = "Route"
    }
    
    func setUpRouteView(startAddressString:String, endAddressString:String){
        routeD?.startAddressString = startAddressString
        routeD?.endAddressString = endAddressString
        startAddress.isHidden = true
        endAddress.isHidden = true
        addressLabel.isHidden = true
        routeInfo.isHidden = false
        detailButton.isEnabled = true
    }
    
    @IBAction func pressStart(sender: AnyObject) {
        // internet connection
        if Reachability.isConnectedToNetwork() == false {
            alertMessage.showAlert(alertString: "No internet connection")
        }

        if( startButton.title == "Start"){
            bounds = GMSCoordinateBounds()
            let popoverContent = (self.storyboard?.instantiateViewController(withIdentifier: "picker"))! as! MenuPickerController
            
            popoverContent.menu = menu
            popoverContent.startController = self
            let nav = presentMenuPopover(popoverContent: popoverContent)
            nav.popoverPresentationController?.barButtonItem = self.startButton
        }else if (startButton.title == "Route") {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()

            setUpRouteView(startAddressString: startAddress.text!, endAddressString: endAddress.text!)
            
            routeD?.createRoute()
            //(routeD.mapTasks.aRoute) is nil
        }else { // end route
            startButton.title = "Start"
            startAddress.isHidden = true
            endAddress.isHidden = true
            routeInfo.isHidden = true
            detailButton.isEnabled = false
            addressLabel.isHidden = false
            // do not save existing route again
            
            if(routeThisRoute != nil){
               // showAlert(alertString: "Can not save existing routes again.")
                routeD?.clearRoute()
            }else{
                showSaveRouteAlert()
            }
            routeThisRoute = nil // for existing route
            aRoute = nil // for new route
            routeD?.mapTasks?.aRoute = nil // is ended
            if((routeTableNav) != nil){
                routeTableNav.dismiss(animated: true, completion: nil)
            }
        }
    }
    
     
    @IBAction func pressDetails(sender: AnyObject) {
        // internet connection
        if Reachability.isConnectedToNetwork() == false {
            alertMessage.showAlert(alertString: "No internet connection")
        }

        let popoverContent = (self.storyboard?.instantiateViewController(withIdentifier: "DirectionTableViewController"))! as! DirectionTableViewController
        popoverContent.startController = self
        popoverContent.preferredContentSize = CGSize(width: 250, height: 350)
       
        //check if it is from existing routes
        if(routeThisRoute != nil){
            popoverContent.route = routeThisRoute
        }else{
            popoverContent.route = routeD?.mapTasks?.aRoute //routeD.mapTasks.directions
        }
        routeTableNav = presentPopover(popoverContent: popoverContent)
        routeTableNav.popoverPresentationController?.barButtonItem = self.detailButton
    }
    
    func updateLabel(data: String){
        addressLabel.text = data
    }
    
    func showSaveRouteAlert(){
        let alertController = UIAlertController(title:nil, message: "Save route?", preferredStyle: .alert)
        let okButton = UIAlertAction(title: "OK",
                                     style: .default) { (alert) -> Void in
                          // save route here
            // get the current route which unnamed
            let predicate = NSPredicate(format: "name = %@", "")
                                        
            let routes = self.realm?.objects(Route.self).filter(predicate)
            self.aRoute = routes?[0]
            try! self.realm!.write {
                //self.aRoute = self.routeD.mapTasks.aRoute
                self.aRoute?.startAddress = self.startAddress.text!
                self.aRoute?.endAddress = self.endAddress.text!
                self.aRoute!.routeInfo = self.routeInfo.text!
                self.aRoute!.polyLines = self.polyLines
                self.aRoute!.endLong = (self.routeD?.mapTasks?.endLong)!
                self.aRoute!.endLat = (self.routeD?.mapTasks?.endLat)!
                self.aRoute!.originLat = (self.routeD?.mapTasks?.originLat)!
                self.aRoute!.originLong = (self.routeD?.mapTasks?.originLong)!
            }

            if let field = alertController.textFields![0] as? UITextField {
                try! self.realm!.write {
                  self.aRoute!.name = field.text!
                }
            } else {
                //
            }
            // writing to realm
            try! self.realm!.write {
                self.realm!.add(self.aRoute!)
                self.person!.routes.append(self.aRoute!) // adding this route
                try! self.realm?.commitWrite()
            }

            OperationQueue().addOperation {
                            
                self.routeInfo.isHidden = true
                self.startAddress.isHidden = true
                self.endAddress.isHidden = true
                self.addressLabel.isHidden = false
          }
                          
        }
        alertController.addAction(okButton)
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel , handler: { (alert) -> Void in
            self.startAddress.isHidden = true
            self.endAddress.isHidden = true
            self.addressLabel.isHidden = false
            self.routeInfo.isHidden = true
        })
        alertController.addAction(cancelButton)
        alertController.addTextField { (textField) in
            textField.placeholder = self.startAddress.text! + "_route"
        }
        present(alertController, animated: true, completion: nil)

        routeD?.clearRoute()
    }
    
    func formatAddressFromPlacemark(placemark: CLPlacemark) -> String {
        return (placemark.addressDictionary!["FormattedAddressLines"] as!
            [String]).joined(separator: ", ")
    }
 
    
}

extension StartController:UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension StartController:UIPopoverPresentationControllerDelegate {
   func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
}

extension StartController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var addressTextField: UITextField!
        var address: String!
        if(textField.tag == 1 ){
            startAddress.resignFirstResponder()
            addressTextField = startAddress
            address = startAddress.text
        }
        if(textField.tag == 2) {
            endAddress.resignFirstResponder()
            addressTextField = endAddress
            address = endAddress.text
        }
       
        // internet connection
        if Reachability.isConnectedToNetwork() == false {
            alertMessage.showAlert(alertString: "No internet connection")
        }
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        CLGeocoder().geocodeAddressString(address!, completionHandler: {(placemarks, error) -> Void in
            if((error) != nil){
                self.alertMessage.showAlert(alertString: error as! String)
                return
            }
            var addresses = [String]()
            if let placemarks = placemarks {
                
                for placemark in placemarks {
                  
                    addresses.append(self.formatAddressFromPlacemark(placemark: placemark))
                }
                addresses.insert("choose one", at: 0)
                let popoverContent = (self.storyboard?.instantiateViewController(withIdentifier: "picker"))! as! MenuPickerController
              
                popoverContent.menu = addresses
                popoverContent.startController = self
                popoverContent.fontsize = 11.0
                popoverContent.addressOption = true
                popoverContent.address = addressTextField
                let nav = self.presentMenuPopover( popoverContent: popoverContent as MenuPickerController)
                nav.popoverPresentationController?.sourceRect = addressTextField.frame
              
            } else {
                self.alertMessage.showAlert(alertString: "address not found. Please check internet connection.")
                
            }
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        } )
        
        return true
    }
    
    func keyboardWillShow( notification: NSNotification) {
       // if(targetTextField.isFirstResponder()){
            view.frame.origin.y = -keyboardHeight(notification: notification)
            
       // }
    }
    
    func keyboardWillHide( notification: NSNotification) {
      //  if(targetTextField.isFirstResponder()){
            view.frame.origin.y += keyboardHeight(notification: notification)
      //  }
    }
    
    
    private func keyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func subscribeToNotification(notification: String, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name(rawValue: notification), object: nil)
    }
    func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
 }

extension StartController: GMSMapViewDelegate{
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        GmapUtils().reverseGeocodeCoordinate(coordinate: position.target ,mapView:mapView, vc: self as UIViewController) // showing current address
        }
    
    func showFriendOnMap(lat: Double, long: Double, name: String, color: UIColor? = UIColor.cyan){
        let position = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let marker = GMSMarker(position: position)
        bounds = bounds?.includingCoordinate(marker.position)
        marker.title = name
        marker.icon = GMSMarker.markerImage(with: color)
        marker.map = mapView
        marker.appearAnimation = kGMSMarkerAnimationPop
    }

    func showFriendsOnMap(){
        let cloudLocation = CloudLocation()
        cloudLocation.startController = self
        let locations = cloudLocation.fetchFreindsLocations()
        for (name,location2d) in locations {
            showFriendOnMap(lat: location2d.latitude,long: location2d.longitude,name: name)
        }
        //showFriendOnMap(lat: 37.2, long: -121.9, name: "susan")

    }
}

extension StartController :CLLocationManagerDelegate  {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
   
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
    
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
          
            showFriendOnMap(lat: location.coordinate.latitude, long: location.coordinate.longitude, name: (person?.name)! , color: UIColor.green) // myself location marker
            locationManager.stopUpdatingLocation()
            // update the Cloud data
            let cloudData = CloudLocation()
            cloudData.startController = self
            cloudData.saveLocationToRealm(person: person!, location: location)
            
            showFriendsOnMap()
        }
        
        
    }
    
    
    
    
}


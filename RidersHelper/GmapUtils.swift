//
//  gmapUtils.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 9/19/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import GoogleMaps
class GmapUtils {
    func reverseGeocodeCoordinate(coordinate:CLLocationCoordinate2D, mapView:GMSMapView, vc:UIViewController) {
        
        // 1
        let geocoder = GMSGeocoder()
        
        // 2

        geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
            if let address = response?.firstResult() {
                let startController = vc as! StartController
                // 3
                let lines = address.lines
                startController.addressLabel.text = lines!.joined(separator: "\n")
                let labelHeight = startController.addressLabel.intrinsicContentSize.height
                mapView.padding = UIEdgeInsets(top: vc.topLayoutGuide.length, left: 0,
                                                    bottom: labelHeight, right: 0)
                
                // 4
                UIView.animate(withDuration: 1.0) {
                    vc.view.layoutIfNeeded()
                }
                
                // show current address
                let startString = startController.addressLabel.text!
                startController.startAddress.text = startString

            }
        }
    }

}

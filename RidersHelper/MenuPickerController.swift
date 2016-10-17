//
//  menuPickerController.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 9/17/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps

class MenuPickerController : UIViewController,UIPickerViewDelegate,UIPickerViewDataSource,   GMSMapViewDelegate{

    @IBOutlet weak var myPickerView: UIPickerView!
    var menu = [String]()
    var mapView: GMSMapView!
    var startButton: UIBarButtonItem!
    var fontsize : CGFloat = 18.0
    var addressOption = false
    var address: UITextField!
    var startController: StartController!
    
    override func viewDidLoad() {
        myPickerView.selectRow(0, inComponent: 0, animated: true)
    }
    override func viewDidDisappear(_ animated: Bool) {
        
        mapView.animate(toZoom: 15.0)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return menu[row]
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return menu.count
    }
        
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var label = view as! UILabel!
        if label == nil {
            label = UILabel()
        }
        
        let data = menu[row]
        let title = NSAttributedString(string: data, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: fontsize, weight: UIFontWeightRegular)])
        label?.attributedText = title
        label?.textAlignment = .center
        return label!
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if(addressOption){
            address.text = menu[row]
        }
        self.dismiss(animated: true, completion: nil)
        
        if row == 1 {
            if(addressOption == false ){
                if( startController.checkExistingRoutes() == false ){
                    startController.alertMessage.showAlert(alertString: "No existing routes.")
                    return
                }
                startController.enterRouteStage()
                // existing routes selected should be presented as a table.
                let popoverContent = (self.storyboard?.instantiateViewController(withIdentifier: "RoutesTableViewController"))! as! RoutesTableViewController
                popoverContent.startController = startController
                popoverContent.preferredContentSize = CGSize(width: 200, height: 300)
                let nav = startController.presentRoutesTablePopover(popoverContent: popoverContent)
                nav.popoverPresentationController?.barButtonItem = startController.startButton
            }
        }else if row == 2 {
            if (addressOption == false ){
                // new routes
                startController.addressLabel.isHidden = true
                startController.startAddress.isHidden = false
                startController.endAddress.isHidden = false
                startController.startButton.title = "Route"
            }
        }
    }
}

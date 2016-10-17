//
//  AlertMessage.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 10/13/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import UIKit
class Alert : NSObject{
    var startController: StartController!
    init(controller: StartController){
        startController = controller
    }
    
    func showAlertWithMessageAndRestart(message: String) {
        let alertController = UIAlertController(title: "RidersHelper", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
            //start over
            self.startController?.enterStartStage()
        }
        alertController.addAction(closeAction)
        startController!.present(alertController, animated: true, completion: nil)
    }
    
    func showAlert(alertString: String) {
        let alert = UIAlertController(title: nil, message: alertString, preferredStyle: .alert)
        let okButton = UIAlertAction(title: "OK",
                                     style: .cancel) { (alert) -> Void in
        }
        alert.addAction(okButton)
        startController.present(alert, animated: true, completion: nil)
    }
    
    
}

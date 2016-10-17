//
//  directionTableViewController.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 9/25/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class DirectionTableViewController : UITableViewController {
    var route: Route! //[String]!
    var startController: StartController!
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return route.routes.count
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "directionTableViewCell")! as UITableViewCell
        cell.textLabel!.numberOfLines = 0
        let routeStep = route.routes[indexPath.row]
        cell.textLabel!.text = routeStep.step
        
        return cell
    }
    
}

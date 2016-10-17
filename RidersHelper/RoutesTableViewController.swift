
//
//  routesTableViewController.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 9/28/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class RoutesTableViewController: UITableViewController {
    var startController: StartController?
    var realm: Realm?
    var persons:Results<Person>?
    var routes : List<Route>?
    var aRoute : Route?
    
    override func viewWillAppear(_ animated: Bool) {
        
        realm = try! Realm()
    
        persons = realm!.objects(Person.self)
        let person = persons!.first
        routes = person?.routes
        
        startController?.routeThisRoute = nil
    
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillAppear((animated))
        if((aRoute ) != nil){
          startController?.setUpRouteView(startAddressString: aRoute!.startAddress, endAddressString: aRoute!.endAddress)
          startController?.routeD?.aRoute = aRoute // for drawing
          startController?.routeThisRoute = aRoute // for directionsTable
          startController?.routeD?.drawThisRoute()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(routes == nil) {
            return 0
        }else {
         return routes!.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RouteTableViewCell")! as UITableViewCell
        cell.textLabel!.text = routes![indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true, completion: nil)
        aRoute = routes![indexPath.row] as Route
     }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if( editingStyle == UITableViewCellEditingStyle.delete){
            let toDelete = routes![indexPath.row] as Route
            //print (toDelete.name)
            try! realm!.write {
                realm!.delete(toDelete)
            }
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            startController?.enterStartStage()
        
        }
    }
}


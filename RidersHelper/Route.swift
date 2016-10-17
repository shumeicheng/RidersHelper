//
//  Route.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 8/31/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import RealmSwift

class Route: Object {
    dynamic var name = ""
    dynamic var startAddress = ""
    dynamic var originLat = 0.0
    dynamic var originLong = 0.0
    dynamic var endAddress = ""
    dynamic var endLat = 0.0
    dynamic var endLong = 0.0

    dynamic var polyLines = ""
    dynamic var routeInfo = ""
    let routes = List<RouteStep>()
    let owners = LinkingObjects(fromType: Person.self, property: "routes")
}

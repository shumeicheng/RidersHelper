//
//  routeStep.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 9/25/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import RealmSwift

class RouteStep : Object {
    dynamic var step = ""
    let fromRoute = LinkingObjects(fromType: Route.self, property: "routes")
}
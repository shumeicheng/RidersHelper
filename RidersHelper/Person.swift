//
//  Person.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 8/31/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import RealmSwift

class Person: Object {
    dynamic var name:String = ""
    let routes = List<Route> ()
    var location : Location?
    let friends = List<Friend> ()
}

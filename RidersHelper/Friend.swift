//
//  Friend.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 10/3/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import RealmSwift

class Friend: Object {
    var name = ""
    var location: Location?
    let fromPerson = LinkingObjects(fromType: Person.self, property: "friends")
}

//
//  CloudLocation.swift
//  RidersHelper
//
//  Created by Shu-Mei Cheng on 10/7/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import CloudKit
import RealmSwift
import UIKit

class CloudLocation: NSObject{
    var database: CKDatabase = CKContainer.default().publicCloudDatabase
    var aRecord: CKRecord!
    var startController: StartController?
    
    func saveLocationToRealm(person:Person,location:CLLocation){
        
        if(person.location == nil){
            try! startController!.realm?.write{
                let loc = Location()
                loc.latitude = location.coordinate.latitude
                loc.longitude = location.coordinate.longitude
                person.location = loc
            }
        }else{
            try! startController!.realm?.write{
                person.location?.longitude = location.coordinate.longitude
                person.location?.latitude = location.coordinate.latitude
            }
        }
        // save to cloud
        let cllocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        saveToCloud(location: cllocation)
    }
    
    func fetchFreindsLocations() -> [String:CLLocationCoordinate2D]{
        downLoadAllFriendsLocations() // updated from icloud first
        
        var locations = [String:CLLocationCoordinate2D]()
        let persons = startController!.realm?.objects(Person.self)
        if(persons!.count == 0) {
            return [String:CLLocationCoordinate2D]()
        }
        let person = persons![0]
        let friends = person.friends
        for friend in friends {
            let name = friend.name
            let location = friend.location
            let lat = location!.latitude
            let long = location!.longitude
            var loc = CLLocationCoordinate2D()
            loc.latitude = lat
            loc.longitude = long
            locations[name] = loc
        }
        return locations
    }
    
    func saveToCloud(location:CLLocation){
        // fetch a record if nil and create one
        var name = UIDevice.current.name
        if (name.isEmpty ){
            name = "EMPTY" // simulator give empty name
        }
        let recordID = CKRecordID(recordName: name)
   
        database.fetch(withRecordID: recordID,   completionHandler: { (record,error) in
            if ((error) != nil){
                print(error) // simulator returns error.
                //return
            }
            if(record == nil){
                // create one
                self.aRecord = CKRecord(recordType: "Person", recordID: recordID)
                
            }else {
              self.aRecord = record
            }
            self.aRecord.setObject(location, forKey: "Location")
            self.aRecord.setObject(name as CKRecordValue?, forKey: "Name")
            self.finalSaveRecord()

        })
    }
    
    func finalSaveRecord(){
        database.save(aRecord, completionHandler: {
            (record,error) in
            guard (error == nil) else {
                print(error)
                return
            }
            
        })
    }
    
    private func checkFriends(realm: Realm, person:Person,name:String) -> Friend{
        var thisFriend:Friend?
        for friend in person.friends {
            if(friend.name == name){
                thisFriend = friend
            }
        }
        if(thisFriend == nil){
            try! realm.write{
                thisFriend = Friend()
                person.friends.append(thisFriend!)
            }
        }
        return thisFriend!
    }
    
    //from Cloud to Realm
    private func downLoadAllFriendsLocations()  {
        let predicate = NSPredicate(value: true)
        let query = CKQuery.init(recordType: "Person", predicate: predicate)
      
        database.perform(query, inZoneWith: nil, completionHandler: { (results,error) in
            for record in results! {
                var name: String!
                let realm = try! Realm()
                var person: Person?
                name = record.object(forKey: "Name") as! String
                if (name == self.startController?.myName){
                    continue; // skip
                }
                //print(record.object(forKey: "Name"))
                var location :CLLocation!
                location = record.object(forKey: "Location") as! CLLocation
                let location2d = location.coordinate
                //print(location2d.latitude,location2d.longitude)
                let persons = realm.objects(Person.self)
                if(persons.count == 0){
                    return
                }else{
                    person = persons[0]
                }
                let thisFriend = self.checkFriends(realm: realm, person: person!,name: name)
                try! realm.write{
                    let loc = Location()
                    loc.latitude = location2d.latitude
                    loc.longitude = location2d.longitude
                    thisFriend.location = loc
                }
            }// for
        })// handler
        
    }
}

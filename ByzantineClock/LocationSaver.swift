//
//  LocationSaver.swift
//  ByzantineClock
//
//  Created by Олег Третьяков on 30.01.16.
//  Copyright © 2016 Олег Третьяков. All rights reserved.
//

import Foundation
import WatchConnectivity

class PlaceInMemory : NSObject, NSCoding  {
    let name : String
    let longitude: Double
    let latitude : Double
    let timezone : NSTimeZone
    
    init (name: String, longitude : Double, latitude : Double, timezone : NSTimeZone) {
        self.name = name
        self.longitude = longitude
        self.latitude = latitude
        self.timezone = timezone
    }
    
    @objc required init(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObjectForKey("name") as! String
        self.latitude = aDecoder.decodeDoubleForKey("latitude")
        self.longitude = aDecoder.decodeDoubleForKey("longitude")
        self.timezone = aDecoder.decodeObjectForKey("timezone") as! NSTimeZone
    }
    
    @objc func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.name, forKey: "name")
        aCoder.encodeDouble(self.latitude, forKey: "latitude")
        aCoder.encodeDouble(self.longitude, forKey: "longitude")
        aCoder.encodeObject(self.timezone, forKey: "timezone")
    }
}

class LocationSaver: NSObject, WCSessionDelegate {
    
    static let sharedInstance = LocationSaver()
    override init() {
        super.init()
        print("LocationSaver is singleton")
        beginSession()
        updateWatch()
    }
    
    func getDataArray() -> [PlaceInMemory] {
        let defaults = NSUserDefaults.init(suiteName: "group.tretiakovy.ByzantineClockSharingDefaults")
        var placeArray : [PlaceInMemory] = []
        
        if let data = defaults!.arrayForKey("places") as! [NSData]? {
            NSKeyedUnarchiver.setClass(PlaceInMemory.self, forClassName: "PlaceInMemory")
            for datas in data {
                let place = NSKeyedUnarchiver.unarchiveObjectWithData(datas) as! PlaceInMemory
                placeArray.append(place)
            }
        }
        return placeArray
    }
    
    func addToDataArray(newData: PlaceInMemory) {
        var places = getDataArray()
        places.append(newData)
        let defaults = NSUserDefaults.init(suiteName: "group.tretiakovy.ByzantineClockSharingDefaults")
        var data : [NSData] = []
        NSKeyedArchiver.setClassName("PlaceInMemory", forClass: PlaceInMemory.self)
        for place in places {
            let toAdd = NSKeyedArchiver.archivedDataWithRootObject(place)
            data.append(toAdd)
        }
        defaults!.setObject(data, forKey: "places")
        defaults!.synchronize()
        updateWatch()
    }
    
    func deleteDataAtIndex(index: Int) {
        var places = getDataArray()
        if places.count > 1 {
            if index == indexOfDefaultData() {
                setIndexOfDefaultData(0)
            }
            places.removeAtIndex(index)
            let defaults = NSUserDefaults.init(suiteName: "group.tretiakovy.ByzantineClockSharingDefaults")
            var data : [NSData] = []
            NSKeyedArchiver.setClassName("PlaceInMemory", forClass: PlaceInMemory.self)
            for place in places {
                let toAdd = NSKeyedArchiver.archivedDataWithRootObject(place)
                data.append(toAdd)
            }
            defaults!.setObject(data, forKey: "places")
            defaults!.synchronize()
            updateWatch()
        }
    }
    
    func indexOfDefaultData() -> Int {
        let defaults = NSUserDefaults.init(suiteName: "group.tretiakovy.ByzantineClockSharingDefaults")
        let index = defaults!.integerForKey("defaultIndex")
        return index
    }
    
    func setIndexOfDefaultData(index: Int) {
        let defaults = NSUserDefaults.init(suiteName: "group.tretiakovy.ByzantineClockSharingDefaults")
        defaults!.setInteger(index, forKey: "defaultIndex")
        defaults!.synchronize()
        updateWatch()
    }
    
    func isDataEmpty() -> Bool {
        let places = getDataArray()
        if places.count == 0 {
            return true
        }
        return false
    }
    
    func beginSession() {
        if WCSession.isSupported() {
            let watchSession = WCSession.defaultSession()
            watchSession.delegate = self
            watchSession.activateSession()
        }
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        updateWatch()
    }
    
    func updateWatch() {
        if WCSession.isSupported() {
            if !isDataEmpty() {
                let places = getDataArray()
                let place = places[indexOfDefaultData()]
                let data = NSKeyedArchiver.archivedDataWithRootObject(place.timezone)
                let info = ["name": place.name, "longitude": place.longitude, "latitude": place.latitude, "timeZone" : data] as [String:AnyObject]
                let watchSession = WCSession.defaultSession()
                if watchSession.paired && watchSession.watchAppInstalled {
                    do {
                        try watchSession.updateApplicationContext(info)
                    } catch let error as NSError {
                        print(error.description)
                    }
                }
            }
        }
    }
}

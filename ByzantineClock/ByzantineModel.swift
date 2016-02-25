//
//  ByzantineModel.swift
//  ByzantineClock
//
//  Created by Олег Третьяков on 06.02.16.
//  Copyright © 2016 Олег Третьяков. All rights reserved.
//

import UIKit

class ByzantineModel: NSObject {
    var localTime : NSDate?
    var sunriseTime : NSDate?
    var sunsetTime : NSDate?
    var timeZone : NSTimeZone?
    
    override init() {
        super.init()
    }
    
    func setVariables() {
        localTime = NSDate()
        timeZone = NSTimeZone()
        let locationSaver = LocationSaver.sharedInstance
        let dataArray = locationSaver.getDataArray()
        if dataArray.count > 0 {
            if locationSaver.indexOfDefaultData() >= dataArray.count {
                locationSaver.setIndexOfDefaultData(0)
            }
            let data = dataArray[locationSaver.indexOfDefaultData()]            
            timeZone = data.timezone
            let sunData = EDSunriseSet.init(date: localTime, timezone: timeZone,
                latitude: data.latitude, longitude: data.longitude)
            sunriseTime = sunData.sunrise
            sunsetTime = sunData.sunset
        }
    }
    
    func changeTime() {
        //Проверяем не изменилась ли дата, если изменилась - меняем sunrise и sunset
        //NSDateComponents определяются по local Timezone
        if (localTime == nil) {
            localTime = NSDate()
        }
        let newTime = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let oldDateComponents = calendar.components([NSCalendarUnit.Day], fromDate: localTime!)
        let newDateComponents = calendar.components([NSCalendarUnit.Day], fromDate: newTime)
        if oldDateComponents.day != newDateComponents.day || sunriseTime == nil {
            setVariables()
        }
        else {
            //Обновляем только localTime и byzantineTime
            localTime = newTime
        }
    }
    
    func byzantineTime() -> Double {
        var sunriseMinutes = 0
        if sunriseTime != nil {
            sunriseMinutes = minutesInDesiredTimeZone(sunriseTime!)
        }
        var sunsetMinutes = 1440
        if sunsetTime != nil {
            sunsetMinutes = minutesInDesiredTimeZone(sunsetTime!)
        }
        if sunsetMinutes < sunriseMinutes {
            sunsetMinutes += 1440
        }
        var currentMinutes = minutesInDesiredTimeZone(NSDate())
        
        var byzantineMinutes = 0.0
        let oneMinute : Double
        if currentMinutes > sunriseMinutes && currentMinutes < sunsetMinutes {
            let dayMinutes = sunsetMinutes - sunriseMinutes
            oneMinute = 720.0 / Double(dayMinutes)
            byzantineMinutes = 360 + Double(currentMinutes - sunriseMinutes) * oneMinute
        } else {
            let nightMinutes =  sunriseMinutes + 1440 - sunsetMinutes
            oneMinute = 720.0 / Double(nightMinutes)
            if currentMinutes < sunsetMinutes {
                currentMinutes += 1440
            }
            byzantineMinutes = 1080 + Double(currentMinutes - sunsetMinutes) * oneMinute
            if byzantineMinutes > 1440 {
                byzantineMinutes = byzantineMinutes - 1440
            }
        }
        return byzantineMinutes
    }
    
    func minutesAboveZero(var minutes: Int) -> Int {
        if minutes < 0 {
            minutes += 1440
        }
        return minutes
    }
    
    func minutesInDesiredTimeZone(time: NSDate) -> Int {
        let calendar = NSCalendar.currentCalendar()
        //Все три компонента считаются по локальному времени, необходимо для перевода времени к нужной зоне
        let minutesFromGMT = (timeZone?.secondsFromGMT)! / 60
        let minutesFromLocalZone = NSTimeZone.localTimeZone().secondsFromGMT / 60
        
        let components = calendar.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: time)
        var minutes = components.hour * 60 + components.minute
        minutes += minutesFromGMT
        minutes -= minutesFromLocalZone
        minutes = minutesAboveZero(minutes)
        return minutes
    }
    
    func byzantineString(byzantineMinutes: Int) -> String {
        let byzantineHours = byzantineMinutes / 60
        return "\(addZero(byzantineHours)):\(addZero(byzantineMinutes - byzantineHours * 60))"
    }
    
    func addZero(number: Int) -> String {
        if number < 10 {
            return "0" + String(number)
        }
        return String(number)
    }
    
}

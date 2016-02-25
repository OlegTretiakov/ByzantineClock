//
//  ViewController.swift
//  ByzantineClock
//
//  Created by Олег Третьяков on 30.01.16.
//  Copyright © 2016 Олег Третьяков. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var clockView: ClockView!
    @IBOutlet weak var labelNoData: UILabel!
    @IBOutlet weak var clockDigits: UILabel!
    @IBOutlet weak var barButton: UIBarButtonItem!
    
    var timer : NSTimer?
    let byzantineModel = ByzantineModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let locationSaver = LocationSaver.sharedInstance
        if locationSaver.isDataEmpty() {
            labelNoData.hidden = false
            clockView.noData = true
        }
        else {
            labelNoData.hidden = true
            clockView.noData = false
            byzantineModel.setVariables()
            reDraw()
            //Запускаем таймер
            timer = NSTimer(timeInterval: 1, target: self, selector: "tickTime", userInfo: nil, repeats: true)
            timer!.tolerance = 0.5
            NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSDefaultRunLoopMode)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        //Останавливаем таймер
        timer?.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tickTime() {
        byzantineModel.changeTime()
        reDraw()
    }
    
    func reDraw() {
        //Отображаем время c учётом timezone
        let byzantineMinutes = Int(byzantineModel.byzantineTime())
        //clockDigits.font = UIFont(name: "LetsgoDigital-Regular", size: 50)
        clockDigits.text = byzantineModel.byzantineString(byzantineMinutes)
        //Рисуем стрелку
        if clockView.timeInMinutes != byzantineMinutes {
            clockView.timeInMinutes = byzantineMinutes
            clockView.setNeedsDisplay()
        }
    }
    
    @IBAction func pressData(sender: AnyObject) {
        var noData = true
        byzantineModel.localTime = NSDate()
        let locationSaver = LocationSaver.sharedInstance
        if !locationSaver.isDataEmpty() {
            noData = false
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "ru")
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.timeZone = byzantineModel.timeZone
        let timeString = dateFormatter.stringFromDate(byzantineModel.localTime!)
        let alert = UIAlertController(title: "Данные", message: timeString, preferredStyle: .ActionSheet)
        alert.popoverPresentationController?.barButtonItem = barButton
        alert.popoverPresentationController?.sourceView = self.view
        
        var definitiveTitle = "\u{1F30D} Не определено"
        
        //Определяем текущие время восхода, захода, продолжительность дня
        if !noData {
            dateFormatter.dateStyle = .NoStyle
            let calendar = NSCalendar.currentCalendar()
            var sunriseString = "Нет восхода"
            var sunriseMinutes = 0
            if byzantineModel.sunriseTime != nil {
                sunriseString = dateFormatter.stringFromDate(byzantineModel.sunriseTime!)
                let sunriseComponents = calendar.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: byzantineModel.sunriseTime!)
                sunriseMinutes = sunriseComponents.hour * 60 + sunriseComponents.minute
            }
            var sunsetString = "Нет захода"
            var sunsetMinutes = 1440
            if byzantineModel.sunsetTime != nil {
                sunsetString = dateFormatter.stringFromDate(byzantineModel.sunsetTime!)
                let sunsetComponents = calendar.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: byzantineModel.sunsetTime!)
                sunsetMinutes = sunsetComponents.hour * 60 + sunsetComponents.minute
            }
            var dayLength : String
            let dateComponents = calendar.components([NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: byzantineModel.localTime!)
            if sunriseMinutes == 0 && sunsetMinutes == 1440 {
                if dateComponents.month > 3 || dateComponents.month < 9 ||
                    (dateComponents.month == 9 && dateComponents.day < 22) || (dateComponents.month == 3 && dateComponents.day > 22) {
                        dayLength = "24:00"
                }
                else {
                    dayLength = "0:00"
                }
            }
            else {
                if sunsetMinutes < sunriseMinutes {
                    sunsetMinutes += 1440
                }
                let dayHours : Int = (sunsetMinutes - sunriseMinutes) / 60
                let dayMinutes = (sunsetMinutes - sunriseMinutes) - dayHours*60
                dayLength = "\(dayHours):\(byzantineModel.addZero(dayMinutes))"
            }
            let dataString = "\u{2600} \(sunriseString)  \u{1F304} \(sunsetString)  \u{1F550} \(dayLength)"
            let infoAction = UIAlertAction(title: dataString, style: .Default) { action in }
            alert.addAction(infoAction)
            
            //Указываем текущее местоположение
            let index = locationSaver.indexOfDefaultData()
            let array = locationSaver.getDataArray()
            definitiveTitle = "\u{1F30D} \(array[index].name)"
        }
        
        let definitiveAction = UIAlertAction(title: definitiveTitle, style: .Default) { action in
            //Переход к списку местоположений
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let locationController = storyboard.instantiateViewControllerWithIdentifier("locationViewController") as! LocationViewController
            self.presentViewController(locationController, animated: true, completion: nil)
        }
        alert.addAction(definitiveAction)
        let cancelAction = UIAlertAction(title: "Закрыть", style: .Cancel) { action in }
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }    
}


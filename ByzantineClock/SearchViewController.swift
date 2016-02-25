//
//  SearchViewController.swift
//  ByzantineClock
//
//  Created by Олег Третьяков on 31.01.16.
//  Copyright © 2016 Олег Третьяков. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var cityText: UITextField!
    @IBOutlet weak var latitudeText: UITextField!
    @IBOutlet weak var longitudeText: UITextField!
    @IBOutlet weak var placePicker: UIPickerView!
    
    var places : [PlaceInMemory] = []
    var lastTimezone = NSTimeZone.localTimeZone()
    let placeChangeNotification = "placeChangeNotification"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Actions
    
    @IBAction func forwardGeocoding(sender: AnyObject) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(cityText.text!) { (placemarks, error) -> Void in
            if error != nil || placemarks!.count < 1 {
                self.alertError()
                self.placePicker.hidden = true
            }
            else  {
                let placemark = placemarks![0] as CLPlacemark
                if let locality = placemark.locality {
                    self.cityText.text = "\(locality), \(placemark.country!)"
                    self.latitudeText.text = String(format:"%.4f", (placemark.location?.coordinate.latitude)!)
                    self.longitudeText.text = String(format:"%.4f", (placemark.location?.coordinate.longitude)!)
                    self.lastTimezone = placemark.timeZone()
                    self.places.removeAll()
                    for mark in placemarks! {
                        let place = PlaceInMemory(name: "\(mark.locality!), \(mark.country!)",
                            longitude: (mark.location?.coordinate.longitude)!,
                            latitude: (mark.location?.coordinate.latitude)!,
                            timezone: mark.timeZone())
                        self.places.append(place)
                    }
                    self.placePicker.hidden = false
                    self.placePicker.reloadAllComponents()
                }
                else {
                    self.alertError()
                }
            }
        }
    }
    @IBAction func reverseGeocoding(sender: AnyObject) {
        self.placePicker.hidden = true
        let geocoder = CLGeocoder()
        if let latitude = Double(latitudeText.text!)  {
                if let longitude = Double(longitudeText.text!) {
                    if latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180 {
                    let location = CLLocation(latitude: latitude, longitude: longitude)
                    geocoder.reverseGeocodeLocation(location) { (placemarks, error) -> Void in
                        if error != nil || placemarks!.count < 1 {
                            self.alertError()
                            self.cityText.text = ""
                            self.lastTimezone = NSTimeZone.localTimeZone()
                        }
                        else  {
                            let placemark = placemarks![0] as CLPlacemark
                            if let locality = placemark.locality {
                                self.cityText.text = "\(locality), \(placemark.country!)"
                                self.lastTimezone = placemark.timeZone()
                            }
                            else {
                                self.alertError()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func alertError() {
        let alert = UIAlertController(title: "Ошибка", message: "Местоположение не найдено", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "ОК", style: .Default, handler: nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func backToLocation(sender: AnyObject) {
        //Проверка корректности данных
        if let latitude = Double(latitudeText.text!)  {
            if let longitude = Double(longitudeText.text!) {
                if cityText.text != "" && latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180 {
                    //Сохранение местоположения
                    let place = PlaceInMemory(name: cityText.text!, longitude: longitude, latitude: latitude, timezone: lastTimezone)
                    let locationSaver = LocationSaver.sharedInstance
                    locationSaver.addToDataArray(place)
                    NSNotificationCenter.defaultCenter().postNotificationName(placeChangeNotification, object: nil)
                }
            }
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    //MARK: - UIPickerViewDataSource
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return places.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return places[row].name
    }
    
    //MARK: - UIPickerViewDelegate
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        cityText.text = places[row].name
        latitudeText.text = String(format:"%.4f", places[row].latitude)
        longitudeText.text = String(format:"%.4f", places[row].longitude)
        lastTimezone = places[row].timezone
    }
    
}

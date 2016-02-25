//
//  LocationViewController.swift
//  ByzantineClock
//
//  Created by Олег Третьяков on 30.01.16.
//  Copyright © 2016 Олег Третьяков. All rights reserved.
//

import UIKit
import CoreLocation

class LocationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    let locationManager = CLLocationManager()
    let placeChangeNotification = "placeChangeNotification"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.bringSubviewToFront(activityIndicator)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "placeChanged:", name:placeChangeNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let locationSaver = LocationSaver.sharedInstance
        return locationSaver.getDataArray().count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("locationCell", forIndexPath: indexPath)
        let locationSaver = LocationSaver.sharedInstance
        let dataArray = locationSaver.getDataArray()
        cell.textLabel?.text = dataArray[indexPath.row].name
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = (indexPath.row % 2) == 0 ? UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0) : UIColor.whiteColor()
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let locationSaver = LocationSaver.sharedInstance
            if locationSaver.getDataArray().count > 1 {
                locationSaver.deleteDataAtIndex(indexPath.row)
                tableView.reloadData()
            }
            else {
                let alert = UIAlertController(title: "Ошибка", message: "Для безаварийной работы приложения запрещается удалять единственное местоположение", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "ОК", style: .Default, handler: nil)
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let locationSaver = LocationSaver.sharedInstance
        locationSaver.setIndexOfDefaultData(indexPath.row)
    }

    // MARK: - Actions
    
    @IBAction func addNewLocation(sender: AnyObject) {
        let alert = UIAlertController(title: "Задайте местоположение", message: nil, preferredStyle: .Alert)
        let autoAction = UIAlertAction(title: "Автоопределение", style: .Default) { action in
            //Автоопределение местоположения
            if  CLLocationManager.authorizationStatus() == .NotDetermined {
                self.locationManager.requestWhenInUseAuthorization()
            } else if CLLocationManager.authorizationStatus() == .Denied || CLLocationManager.authorizationStatus() == .Restricted {
                let autoAlert = UIAlertController(title: "Ошибка авторизации", message: "Вы не разрешили использовать сервисы геолокации в этом приложении. Включите их в 'Настройки - Конфиденциальность - Службы геолокации'", preferredStyle: .Alert)
                let cancelAction = UIAlertAction(title: "Отмена", style: .Cancel, handler: nil)
                autoAlert.addAction(cancelAction)
                let okAction = UIAlertAction(title: "ОК", style: .Default) { action in
                    let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString)
                    UIApplication.sharedApplication().openURL(settingsURL!)
                }
                autoAlert.addAction(okAction)
                self.presentViewController(autoAlert, animated: true, completion: nil)
            } else {
                self.locationManager.startUpdatingLocation()
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    self.activityIndicator.startAnimating()
                }
            }
        }
        alert.addAction(autoAction)
        let manualAction = UIAlertAction(title: "Задать вручную", style: .Default) { action in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let searchController = storyboard.instantiateViewControllerWithIdentifier("searchViewController") as! SearchViewController
            self.presentViewController(searchController, animated: true, completion: nil)
        }
        alert.addAction(manualAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func backToMain(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(placeChangeNotification, object: nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc func placeChanged(notification: NSNotification){
        tableView.reloadData()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let geocoder = CLGeocoder()
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let location = CLLocation(latitude: latitude, longitude: longitude)
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) -> Void in
                let latitude = location.coordinate.latitude
                let longitude = location.coordinate.longitude
                var name = ""
                var timeZone = APTimeZones.sharedInstance().timeZoneWithLocation(location)
                if error != nil || placemarks!.count < 1 {
                    //No action
                }
                else  {
                    let placemark = placemarks![0] as CLPlacemark
                    name = "\(placemark.locality!), \(placemark.country!)"
                    timeZone = placemark.timeZone()
                }
                let place = PlaceInMemory(name: name, longitude: longitude, latitude: latitude, timezone: timeZone)
                let locationSaver = LocationSaver.sharedInstance
                locationSaver.addToDataArray(place)
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    self.activityIndicator.stopAnimating()
                    self.tableView.reloadData()
                }
            }
        }
        locationManager.stopUpdatingLocation()
    }
    
}

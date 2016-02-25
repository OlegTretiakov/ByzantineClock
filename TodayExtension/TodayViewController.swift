//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by Олег Третьяков on 06.02.16.
//  Copyright © 2016 Олег Третьяков. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
    let placeChangeNotification = "placeChangeNotification"
    let byzantineModel = ByzantineModel()
    var timer : NSTimer?
    @IBOutlet var clockView: ClockView!    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        self.preferredContentSize = CGSizeMake(320, 296)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
        timer = NSTimer(timeInterval: 1, target: self, selector: "tickTime", userInfo: nil, repeats: true)
        timer!.tolerance = 0.5
        NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSDefaultRunLoopMode)
    }
    
    override func viewWillDisappear(animated: Bool) {
        timer?.invalidate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateData() {
        let locationSaver = LocationSaver.sharedInstance
        if locationSaver.isDataEmpty() {
            clockView.noData = true
        }
        else {
            clockView.noData = false
            byzantineModel.setVariables()
            reDraw()
        }
    }
    
    func tickTime() {
        byzantineModel.changeTime()
        reDraw()
    }
    
    func reDraw() {
        let byzantineMinutes = Int(byzantineModel.byzantineTime())
        if clockView.timeInMinutes != byzantineMinutes {
            clockView.timeInMinutes = byzantineMinutes
            clockView.setNeedsDisplay()
        }
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        completionHandler(NCUpdateResult.NoData)
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
}

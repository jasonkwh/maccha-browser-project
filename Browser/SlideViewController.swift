/*
*  SlideViewController.swift
*  quaza-browser-project
*
*  This Source Code Form is subject to the terms of the Mozilla Public
*  License, v. 2.0. If a copy of the MPL was not distributed with this
*  file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*  Created by Jason Wong on 6/02/2016.
*  Copyright © 2016 Studios Pâtes, Jason Wong (mail: jasonkwh@gmail.com).
*/

import UIKit

class SlideViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MGSwipeTableCellDelegate {
    @IBOutlet weak var bgText: UILabel!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var ntButton: UIButton!
    @IBOutlet weak var sfButton: UIButton!
    @IBOutlet weak var htButton: UIButton!
    @IBOutlet weak var bkButton: UIButton!
    @IBOutlet weak var sgButton: UIButton!
    @IBOutlet weak var abButton: UIButton!
    @IBOutlet weak var windowView: UITableView! {
        didSet {
            windowView.dataSource = self
        }
    }
    var bkButtonSwitch: Bool = false //functions
    var htButtonSwitch: Bool = false //functions
    
    //Temporary store array
    var tempArray_title = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //get value from struct variable
        tempArray_title = slideViewValue.windowStoreTitle
        
        //define basic style of slide view
        self.view.backgroundColor = UIColor(netHex:0x2E2E2E)
        toolbar.barTintColor = UIColor(netHex:0x2E2E2E)
        toolbar.clipsToBounds = true
        windowView.backgroundColor = UIColor.clearColor()
        windowView.separatorStyle = .None
        windowView.delegate = self
        windowView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        
        //button displays
        displaySafariButton()
        displayHistoryButton()
        displayBookmarkButton()
        displaySettingsButton()
        displayAboutButton()
        displayNewtabButton()
    }
    
    //windows management functions
    override func viewDidAppear(animated: Bool) {
        
        //get value from struct variable
        tempArray_title = slideViewValue.windowStoreTitle
        
        bgText.text = "Quaza"
        windowView.reloadDataAnimateWithWave(.LeftToRightWaveAnimation)
        
        if(slideViewValue.scrollCellAction == false) {
            //scroll the tableView to display the latest tab
            let indexPath = NSIndexPath(forRow: windowView.numberOfRowsInSection(windowView.numberOfSections-1)-1, inSection: (windowView.numberOfSections-1))
            windowView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
        //set up readbility button style each time when the view appears
        if(slideViewValue.readActions == false) {
            sgButton.setImage(UIImage(named: "Read"), forState: UIControlState.Normal)
        }
        else if(slideViewValue.readActions == true) {
            sgButton.setImage(UIImage(named: "Read-filled"), forState: UIControlState.Normal)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tempArray_title.count
    }
    
    //design of different cells
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("programmaticCell") as! MGSwipeTableCell!
        if cell == nil {
            cell = MGSwipeTableCell(style: .Subtitle, reuseIdentifier: "programmaticCell")
        }
        
        //shorten the website title
        var titleName = tempArray_title[indexPath.row]
        if(titleName == "") {
            titleName = "Untitled"
        }
        cell.textLabel?.text = "                 " + titleName
        cell.delegate = self
        
        //cell design
        if(indexPath.row == slideViewValue.windowCurTab) {
            cell.backgroundColor = slideViewValue.windowCurColour
        }
        else {
            cell.backgroundColor = UIColor(netHex:0x333333)
        }
        cell.textLabel?.textColor = UIColor(netHex: 0xECF0F1)
        cell.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        
        //configure right buttons
        cell.rightButtons = [MGSwipeButton(title: "Close", backgroundColor: UIColor(netHex:0xE74C3C), callback: {
            (sender: MGSwipeTableCell!) -> Bool in
            //LOGICs of removing tabs
            if(self.tempArray_title.count > 1) {
                if(slideViewValue.windowCurTab != indexPath.row) {
                    self.tempArray_title.removeAtIndex(indexPath.row)
                    slideViewValue.windowStoreUrl.removeAtIndex(indexPath.row)
                    slideViewValue.scrollPosition.removeAtIndex(indexPath.row)
                    if(indexPath.row < slideViewValue.windowCurTab) {
                        slideViewValue.windowCurTab--
                    }
                    slideViewValue.windowStoreTitle = self.tempArray_title
                }
                else {
                    if(slideViewValue.windowCurTab == (self.tempArray_title.count - 1)) {
                        self.tempArray_title.removeAtIndex(indexPath.row)
                        slideViewValue.windowStoreUrl.removeAtIndex(indexPath.row)
                        slideViewValue.scrollPosition.removeAtIndex(indexPath.row)
                        slideViewValue.windowCurTab--
                    }
                    else {
                        self.tempArray_title.removeAtIndex(indexPath.row)
                        slideViewValue.windowStoreUrl.removeAtIndex(indexPath.row)
                        slideViewValue.scrollPosition.removeAtIndex(indexPath.row)
                    }
                    slideViewValue.windowStoreTitle = self.tempArray_title
                    slideViewValue.deleteTab = true
                }
            }
            else if(self.tempArray_title.count == 1) {
                slideViewValue.windowStoreUrl[0] = "about:blank"
                self.tempArray_title[0] = ""
                slideViewValue.windowStoreTitle = self.tempArray_title
                slideViewValue.scrollPosition[0] = 0.0
                slideViewValue.deleteTab = true
                self.revealViewController().rightRevealToggleAnimated(true)
            }
            self.windowView.reloadData()
            return true
        })]
        cell.rightSwipeSettings.transition = MGSwipeTransition.Static
        cell.rightExpansion.buttonIndex = 0
        cell.rightExpansion.fillOnTrigger = true
        
        return cell
    }
    
    //actions of the cells
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        if(slideViewValue.windowCurTab != indexPath.row) {
            slideViewValue.windowCurTab = indexPath.row
            slideViewValue.cellActions = true
        }
        slideViewValue.scrollCellAction = true
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    //function to display New tab button with the height 30 and width 30
    func displayNewtabButton() {
        ntButton.setImage(UIImage(named: "Addtab"), forState: UIControlState.Normal)
        ntButton.addTarget(self, action: "newtabAction", forControlEvents: UIControlEvents.TouchUpInside)
        ntButton.frame = CGRectMake(0, 0, 25, 25)
    }
    
    //function to display safari button with the height 30 and width 30
    func displaySafariButton() {
        sfButton.setImage(UIImage(named: "Safari"), forState: UIControlState.Normal)
        sfButton.addTarget(self, action: "safariAction", forControlEvents: UIControlEvents.TouchUpInside)
        sfButton.frame = CGRectMake(0, 0, 25, 25)
    }
    
    //function to display history button with the height 30 and width 30
    func displayHistoryButton() {
        htButton.setImage(UIImage(named: "History"), forState: UIControlState.Normal)
        htButton.addTarget(self, action: "historyAction", forControlEvents: UIControlEvents.TouchUpInside)
        htButton.frame = CGRectMake(0, 0, 25, 25)
    }
    
    //function to display Bookmark button with the height 30 and width 30
    func displayBookmarkButton() {
        bkButton.setImage(UIImage(named: "Bookmark"), forState: UIControlState.Normal)
        bkButton.addTarget(self, action: "bookmarkAction", forControlEvents: UIControlEvents.TouchUpInside)
        bkButton.frame = CGRectMake(0, 0, 25, 25)
    }
    
    //function to display Settings button with the height 30 and width 30
    func displaySettingsButton() {
        sgButton.addTarget(self, action: "settingsAction", forControlEvents: UIControlEvents.TouchUpInside)
        sgButton.frame = CGRectMake(0, 0, 25, 25)
    }
    
    //function to display About button with the height 30 and width 30
    func displayAboutButton() {
        abButton.setImage(UIImage(named: "About"), forState: UIControlState.Normal)
        abButton.addTarget(self, action: "aboutAction", forControlEvents: UIControlEvents.TouchUpInside)
        abButton.frame = CGRectMake(0, 0, 25, 25)
    }
    
    func newtabAction() {
        slideViewValue.newtabButton = true
        slideViewValue.scrollCellAction = false
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    func aboutAction() {
        slideViewValue.alertPopup(1, message: "") //show about message popup
    }
    
    func safariAction() {
        slideViewValue.safariButton = true
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    func historyAction() {
        if(htButtonSwitch == false) {
            htButton.setImage(UIImage(named: "History-filled"), forState: UIControlState.Normal)
            htButtonSwitch = true
            bkButton.setImage(UIImage(named: "Bookmark"), forState: UIControlState.Normal)
            bkButtonSwitch = false
        }
        else {
            htButton.setImage(UIImage(named: "History"), forState: UIControlState.Normal)
            htButtonSwitch = false
        }
    }
    
    func bookmarkAction() {
        if(bkButtonSwitch == false) {
            bkButton.setImage(UIImage(named: "Bookmark-filled"), forState: UIControlState.Normal)
            bkButtonSwitch = true
            htButton.setImage(UIImage(named: "History"), forState: UIControlState.Normal)
            htButtonSwitch = false
        }
        else {
            bkButton.setImage(UIImage(named: "Bookmark"), forState: UIControlState.Normal)
            bkButtonSwitch = false
        }
    }
    
    func settingsAction() {
        if(slideViewValue.readActions == false) {
            sgButton.setImage(UIImage(named: "Read-filled"), forState: UIControlState.Normal)
            slideViewValue.readActions = true
        }
        else if(slideViewValue.readActions == true) {
            sgButton.setImage(UIImage(named: "Read"), forState: UIControlState.Normal)
            slideViewValue.readRecover = true
        }
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

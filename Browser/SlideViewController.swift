/*
*  SlideViewController.swift
*  Maccha Browser
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
    @IBAction func deleteAllTabCheck(sender: AnyObject) {
        //function to define tab deletion
        if(mainView == false) {
         //remove all history records
         slideViewValue.historyUrl.removeAll()
         slideViewValue.historyTitle.removeAll()
         slideViewValue.htButtonSwitch = false
         
         //back to original tab
         historyBackToNormal()
         self.view.makeToast("Tabs", duration: 0.8, position: CGPoint(x: self.view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70))
         } else {
         //reset main arrays
         slideViewValue.windowStoreTitle.removeAll()
         slideViewValue.windowStoreTitle.append("")
         slideViewValue.windowStoreUrl.removeAll()
         slideViewValue.windowStoreUrl.append("about:blank")
         slideViewValue.scrollPosition.removeAll()
         slideViewValue.scrollPosition.append("0.0")
         slideViewValue.windowCurTab = 0
         
         //reset readActions
         slideViewValue.readActions = false
         slideViewValue.readRecover = false
         slideViewValue.readActionsCheck = false
         self.sgButton.setImage(UIImage(named: "Read"), forState: UIControlState.Normal)
         
         //open tabs in background
         WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL:NSURL(string: slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])!))
         slideViewValue.scrollPositionSwitch = true
         self.revealViewController().rightRevealToggleAnimated(true)
         }
    }
    @IBAction func deleteAllTab(sender: AnyObject) {
        if(trashButton == false) {
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.navBar.frame.origin.x = 0
                }, completion: { finished in
            })
            trashButton = true
        } else {
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.navBar.frame.origin.x = -55
                }, completion: { finished in
            })
            trashButton = false
        }
    }
    @IBOutlet weak var navBar: UINavigationBar!
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
    var tempArray_title = [String]() //Temporary store array
    var style = ToastStyle() //initialise toast
    var mainView: Bool = false
    var trashButton: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //define basic style of slide view
        self.view.backgroundColor = UIColor(netHex:0x2E2E2E)
        toolbar.barTintColor = UIColor(netHex:0x2E2E2E)
        toolbar.clipsToBounds = true
        view.layer.cornerRadius = 5 //set corner radius of uiview
        view.layer.masksToBounds = true
        windowView.backgroundColor = UIColor.clearColor()
        windowView.separatorStyle = .None
        windowView.delegate = self
        windowView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        navBar.translucent = false
        navBar.barTintColor = UIColor(netHex:0x2E2E2E)
        navBar.clipsToBounds = true
        navBar.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        
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
        navBar.frame.origin.x = -55
        
        //set Toast alert style
        style.messageColor = UIColor(netHex: 0x2E2E2E)
        style.backgroundColor = UIColor(netHex:0xECF0F1)
        ToastManager.shared.style = style
        
        //get value from struct variable
        tempArray_title = slideViewValue.windowStoreTitle
        mainView = true
        
        bgText.text = "maccha"
        windowView.reloadData()
        
        scrollLastestTab(true)
        
        //set up readbility button style each time when the view appears
        if(slideViewValue.readActions == false) {
            sgButton.setImage(UIImage(named: "Read"), forState: UIControlState.Normal)
        }
        else if(slideViewValue.readActions == true) {
            sgButton.setImage(UIImage(named: "Read-filled"), forState: UIControlState.Normal)
        }
        
        //reset history button
        htButton.setImage(UIImage(named: "History"), forState: UIControlState.Normal)
        slideViewValue.htButtonSwitch = false
    }
    
    override func viewDidDisappear(animated: Bool) {
        //reset to original Toast alert style
        style.messageColor = UIColor(netHex: 0xECF0F1)
        style.backgroundColor = UIColor(netHex:0x444444)
        ToastManager.shared.style = style
    }
    
    func scrollLastestTab(animate: Bool) {
        //scroll the tableView to display the latest tab
        let indexPath = NSIndexPath(forRow: slideViewValue.windowCurTab, inSection: (windowView.numberOfSections-1))
        windowView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: animate)
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
            titleName = "untitled"
        }
        cell.textLabel?.text = "                 " + titleName
        cell.textLabel?.font = UIFont.systemFontOfSize(16.0)
        cell.delegate = self
        
        //cell design
        if(indexPath.row == slideViewValue.windowCurTab) && (slideViewValue.htButtonSwitch == false) {
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
            if(slideViewValue.htButtonSwitch == false) { //normal mode
                if(self.tempArray_title.count > 1) {
                    if(slideViewValue.windowCurTab != indexPath.row) {
                        self.tempArray_title.removeAtIndex(indexPath.row)
                        slideViewValue.windowStoreUrl.removeAtIndex(indexPath.row)
                        slideViewValue.scrollPosition.removeAtIndex(indexPath.row)
                        if(indexPath.row < slideViewValue.windowCurTab) {
                            slideViewValue.windowCurTab -= 1
                        }
                        slideViewValue.windowStoreTitle = self.tempArray_title
                    }
                    else {
                        if(slideViewValue.windowCurTab == (self.tempArray_title.count - 1)) {
                            self.tempArray_title.removeAtIndex(indexPath.row)
                            slideViewValue.windowStoreUrl.removeAtIndex(indexPath.row)
                            slideViewValue.scrollPosition.removeAtIndex(indexPath.row)
                        }
                        else {
                            self.tempArray_title.removeAtIndex(indexPath.row)
                            slideViewValue.windowStoreUrl.removeAtIndex(indexPath.row)
                            slideViewValue.scrollPosition.removeAtIndex(indexPath.row)
                        }
                        if(slideViewValue.windowCurTab != 0) {
                            slideViewValue.windowCurTab -= 1
                        }
                        slideViewValue.windowStoreTitle = self.tempArray_title
                        
                        //reset readActions
                        slideViewValue.readActions = false
                        slideViewValue.readRecover = false
                        slideViewValue.readActionsCheck = false
                        self.sgButton.setImage(UIImage(named: "Read"), forState: UIControlState.Normal)
                        
                        //open tabs in background
                        WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL: NSURL(string: slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 15))
                        slideViewValue.scrollPositionSwitch = true
                    }
                }
                else if(self.tempArray_title.count == 1) {
                    slideViewValue.windowStoreUrl[0] = "about:blank"
                    self.tempArray_title[0] = ""
                    slideViewValue.windowStoreTitle = self.tempArray_title
                    slideViewValue.scrollPosition[0] = "0.0"
                    
                    //reset readActions
                    slideViewValue.readActions = false
                    slideViewValue.readRecover = false
                    slideViewValue.readActionsCheck = false
                    self.sgButton.setImage(UIImage(named: "Read"), forState: UIControlState.Normal)
                    
                    //open tabs in background
                    WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL:NSURL(string: "about:blank")!))
                    slideViewValue.scrollPositionSwitch = true
                    self.revealViewController().rightRevealToggleAnimated(true)
                }
            }
            else if(slideViewValue.htButtonSwitch == true) { //"history" mode
                self.tempArray_title.removeAtIndex(indexPath.row)
                slideViewValue.historyUrl.removeAtIndex(indexPath.row)
                slideViewValue.historyTitle = self.tempArray_title
                if(self.tempArray_title.count == 0) { //switch off history while history is empty
                    self.historyBackToNormal()
                    self.view.makeToast("History is empty...", duration: 0.8, position: CGPoint(x: self.view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70)) //alert user
                }
            }
            self.windowView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, self.windowView.numberOfSections)), withRowAnimation: .Automatic)
            return true
        })]
        cell.rightSwipeSettings.transition = MGSwipeTransition.Static
        cell.rightExpansion.buttonIndex = 0
        cell.rightExpansion.fillOnTrigger = true
        
        return cell
    }
    
    //actions of the cells
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        if(slideViewValue.htButtonSwitch == false) { //normal changing tabs
            if(slideViewValue.windowCurTab != indexPath.row) { //open link if user not touch current tab, else not loading
                slideViewValue.windowCurTab = indexPath.row
                slideViewValue.cellActions = true
            }
        } else if(slideViewValue.htButtonSwitch == true) { //use History feature
            slideViewValue.htButtonIndex = indexPath.row //pass row value to struct variable
            slideViewValue.cellActions = true
        }
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    //function to display New tab button with the height 30 and width 30
    func displayNewtabButton() {
        ntButton.setImage(UIImage(named: "Addtab"), forState: UIControlState.Normal)
        ntButton.addTarget(self, action: #selector(SlideViewController.newtabAction), forControlEvents: UIControlEvents.TouchUpInside)
        ntButton.frame = CGRectMake(0, 0, 25, 25)
    }
    
    //function to display safari button with the height 30 and width 30
    func displaySafariButton() {
        sfButton.setImage(UIImage(named: "Safari"), forState: UIControlState.Normal)
        sfButton.addTarget(self, action: #selector(SlideViewController.safariAction), forControlEvents: UIControlEvents.TouchUpInside)
        sfButton.frame = CGRectMake(0, 0, 25, 25)
    }
    
    //function to display history button with the height 30 and width 30
    func displayHistoryButton() {
        htButton.setImage(UIImage(named: "History"), forState: UIControlState.Normal)
        htButton.addTarget(self, action: #selector(SlideViewController.historyAction), forControlEvents: UIControlEvents.TouchUpInside)
        htButton.frame = CGRectMake(0, 0, 25, 25)
    }
    
    //function to display Bookmark button with the height 30 and width 30
    func displayBookmarkButton() {
        bkButton.setImage(UIImage(named: "Bookmark"), forState: UIControlState.Normal)
        bkButton.addTarget(self, action: #selector(SlideViewController.bookmarkAction), forControlEvents: UIControlEvents.TouchUpInside)
        bkButton.frame = CGRectMake(0, 0, 25, 25)
    }
    
    //function to display Settings button with the height 30 and width 30
    func displaySettingsButton() {
        sgButton.addTarget(self, action: #selector(SlideViewController.settingsAction), forControlEvents: UIControlEvents.TouchUpInside)
        sgButton.frame = CGRectMake(0, 0, 25, 25)
    }
    
    //function to display About button with the height 30 and width 30
    func displayAboutButton() {
        abButton.setImage(UIImage(named: "About"), forState: UIControlState.Normal)
        abButton.addTarget(self, action: #selector(SlideViewController.aboutAction), forControlEvents: UIControlEvents.TouchUpInside)
        abButton.frame = CGRectMake(0, 0, 25, 25)
    }
    
    func newtabAction() {
        slideViewValue.newtabButton = true
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
        if(slideViewValue.htButtonSwitch == false) {
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.navBar.frame.origin.x = -55
                }, completion: { finished in
            })
            if(slideViewValue.historyTitle.count > 0) { //avoid size < 0 bug crash
                htButton.setImage(UIImage(named: "History-filled"), forState: UIControlState.Normal)
                slideViewValue.htButtonSwitch = true
                bkButton.setImage(UIImage(named: "Bookmark"), forState: UIControlState.Normal)
                bkButtonSwitch = false
                bgText.text = "history"
                tempArray_title = slideViewValue.historyTitle
                mainView = false
                windowView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, windowView.numberOfSections)), withRowAnimation: .Automatic)
                self.view.makeToast("History", duration: 0.8, position: CGPoint(x: self.view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70))
                scrollLastestTab(true)
            } else {
                self.view.makeToast("History is empty...", duration: 0.8, position: CGPoint(x: self.view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70)) //alert user instead of switching to History
            }
        }
        else {
            historyBackToNormal()
            self.view.makeToast("Tabs", duration: 0.8, position: CGPoint(x: self.view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70))
        }
    }
    
    func historyBackToNormal() { //switch History feature off
        htButton.setImage(UIImage(named: "History"), forState: UIControlState.Normal)
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.navBar.frame.origin.x = -55
            }, completion: { finished in
        })
        slideViewValue.htButtonSwitch = false
        bgText.text = "maccha"
        tempArray_title = slideViewValue.windowStoreTitle
        mainView = true
        windowView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, windowView.numberOfSections)), withRowAnimation: .Automatic)
    }
    
    func bookmarkAction() {
        if(bkButtonSwitch == false) {
            bkButton.setImage(UIImage(named: "Bookmark-filled"), forState: UIControlState.Normal)
            bkButtonSwitch = true
            htButton.setImage(UIImage(named: "History"), forState: UIControlState.Normal)
            slideViewValue.htButtonSwitch = false
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

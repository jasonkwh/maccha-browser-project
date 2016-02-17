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
    var testArray = [String]()
    var scrollCellAction: Bool = false
    var bkButtonSwitch: Bool = false
    var htButtonSwitch: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //define basic style of slide view
        self.view.backgroundColor = UIColor(netHex:0x2E2E2E)
        toolbar.barTintColor = UIColor(netHex:0x2E2E2E)
        toolbar.clipsToBounds = true
        windowView.backgroundColor = UIColor(netHex:0x2E2E2E)
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
        windowView.reloadData()
        
        if(scrollCellAction == false) {
            //scroll the tableView to display the latest tab
            let indexPath = NSIndexPath(forRow: windowView.numberOfRowsInSection(windowView.numberOfSections-1)-1, inSection: (windowView.numberOfSections-1))
            windowView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
        scrollCellAction = false
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return slideViewValue.windowStoreTitle.count
    }
    
    //design of different cells
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("programmaticCell") as! MGSwipeTableCell!
        if cell == nil {
            cell = MGSwipeTableCell(style: .Subtitle, reuseIdentifier: "programmaticCell")
        }
        
        //shorten the website title
        var titleName = slideViewValue.windowStoreTitle[indexPath.row]
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
            cell.backgroundColor = UIColor(netHex:0x2E2E2E)
        }
        cell.textLabel?.textColor = UIColor(netHex: 0xECF0F1)
        cell.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        
        //configure right buttons
        cell.rightButtons = [MGSwipeButton(title: "Delete", backgroundColor: UIColor(netHex:0xE74C3C), callback: {
            (sender: MGSwipeTableCell!) -> Bool in
            print("Delete")
            return true
        })]
        cell.rightSwipeSettings.transition = MGSwipeTransition.Static
        cell.rightExpansion.buttonIndex = indexPath.row
        cell.rightExpansion.fillOnTrigger = true
        
        return cell
    }
    
    //actions of the cells
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        if(slideViewValue.windowCurTab != indexPath.row) {
            slideViewValue.windowCurTab = indexPath.row
            slideViewValue.cellActions = true
        }
        scrollCellAction = true
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
        sgButton.setImage(UIImage(named: "Settings"), forState: UIControlState.Normal)
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
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    func aboutAction() {
        let view = ModalView.instantiateFromNib()
        let window = UIApplication.sharedApplication().delegate?.window!
        let modal = PathDynamicModal()
        modal.showMagnitude = 200.0
        modal.closeMagnitude = 130.0
        view.closeButtonHandler = {[weak modal] in
            modal?.closeWithLeansRandom()
            return
        }
        view.bottomButtonHandler = {[weak modal] in
            modal?.closeWithLeansRandom()
            return
        }
        modal.show(modalView: view, inView: window!)
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
        print("setting pressed")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

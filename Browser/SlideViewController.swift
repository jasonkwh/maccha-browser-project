//
//  SlideViewController.swift
//  quaza-browser-project
//
//  Created by Jason Wong on 6/02/2016.
//  Copyright © 2016 Studios Pâtes, Jason Wong (mail: jasonkwh@gmail.com).
//

import UIKit

class SlideViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //define basic style of slide view
        self.view.backgroundColor = UIColor(netHex:0x2E2E2E)
        toolbar.barTintColor = UIColor(netHex:0x2E2E2E)
        toolbar.clipsToBounds = true
        windowView.backgroundColor = UIColor(netHex:0x2E2E2E)
        windowView.separatorColor = UIColor(netHex:0x2E2E2E)
        windowView.delegate = self
        windowView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        windowView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "myCell")
        
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
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return slideViewValue.windowStoreTitle.count
    }
    
    //design of different cells
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("myCell", forIndexPath: indexPath) as UITableViewCell
        
        //shorten the website title
        var siteTitle = slideViewValue.windowStoreTitle[indexPath.row]
        if(siteTitle.characters.count > 15) {
            siteTitle = siteTitle.trunc(15)
        }
        cell.textLabel?.text = siteTitle
        
        //cell design
        cell.backgroundColor = UIColor(netHex:0x2E2E2E)
        cell.textLabel?.textColor = UIColor(netHex: 0xECF0F1)
        cell.textLabel?.textAlignment = .Right
        cell.transform = CGAffineTransformMakeRotation(CGFloat(M_PI));
        return cell
    }
    
    //actions of the cells
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        slideViewValue.windowCurTab = indexPath.row
        slideViewValue.cellActions = true
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
        slideViewValue.aboutButton = true
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    func safariAction() {
        slideViewValue.safariButton = true
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    func historyAction() {
        print("History pressed!")
    }
    
    func bookmarkAction() {
        print("Bookmark pressed!")
    }
    
    func settingsAction() {
        print("Settings pressed!")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//method to shorten strings to ...
extension String {
    func trunc(length: Int, trailing: String? = "...") -> String {
        if self.characters.count > length {
            return self.substringToIndex(self.startIndex.advancedBy(length)) + (trailing ?? "")
        } else {
            return self
        }
    }
}

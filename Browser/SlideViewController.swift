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

class SlideViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate, MGSwipeTableCellDelegate {
    @IBOutlet weak var trashBut: UIBarButtonItem!
    @IBOutlet weak var searchContainer: UINavigationBar!
    @IBAction func deleteAllTabCheck(sender: AnyObject) {
        //function to define tab deletion
        if(mainView == 0) {
            //remove all history records
            slideViewValue.historyUrl.removeAll()
            slideViewValue.historyTitle.removeAll()
            slideViewValue.historyDate.removeAll()
            slideViewValue.htButtonSwitch = false
            
            //back to original tab
            historyBackToNormal()
            view.makeToast("Records are clear...", duration: 0.8, position: CGPoint(x: view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70))
        } else if(mainView == 2) {
            //remove all history records
            slideViewValue.likesUrl.removeAll()
            slideViewValue.likesTitle.removeAll()
            slideViewValue.bkButtonSwitch = false
            
            //back to original tab
            bookmarkBackToNormal()
            view.makeToast("Likes are clear...", duration: 0.8, position: CGPoint(x: view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70))
        } else if(mainView == 1) {
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
            
            sgButton.setImage(UIImage(named: "Read"), forState: UIControlState.Normal)
            
            //open tabs in background
            WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL:NSURL(string: slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])!))
            slideViewValue.scrollPositionSwitch = true
            revealViewController().rightRevealToggleAnimated(true)
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
    var tempArray_title = [String]() //Temporary store array
    var style = ToastStyle() //initialise toast
    var mainView: Int = 0 //0: History view, 1: Main view, 2: Likes view
    var trashButton: Bool = false
    var slideUpdate: Bool = false
    var filteredTableData = [String]()
    var resultSearchController = UISearchController()
    let searchFrame = CGRect(x: 6, y: 0, width: 228, height: 44)
    var tapPressRecognizer = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //define basic style of slide view
        view.backgroundColor = UIColor(netHex:0x2E2E2E)
        toolbar.barTintColor = UIColor(netHex:0x2E2E2E)
        toolbar.clipsToBounds = true
        view.layer.cornerRadius = 5 //set corner radius of uiview
        view.layer.masksToBounds = true
        windowView.backgroundColor = UIColor.clearColor()
        windowView.separatorStyle = .None
        windowView.delegate = self
        windowView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        windowView.rowHeight = 45.0
        navBar.translucent = false
        navBar.barTintColor = UIColor(netHex:0x2E2E2E)
        navBar.clipsToBounds = true
        navBar.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        searchContainer.clipsToBounds = true
        searchContainer.translucent = false
        searchContainer.barTintColor = UIColor(netHex:0x2E2E2E)
        definesPresentationContext = true
        
        //long press to show the action sheet
        tapPressRecognizer.delegate = self
        tapPressRecognizer.addTarget(self, action: #selector(SlideViewController.onTapPress(_:)))
        windowView.addGestureRecognizer(tapPressRecognizer)
        
        //set search bar and search controller
        if #available(iOS 9.0, *) {
            self.resultSearchController.loadViewIfNeeded()// iOS 9
        } else {
            // Fallback on earlier versions
            let _ = self.resultSearchController.view // iOS 8
        }
        //search controller & search bar settings and designs
        self.resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.delegate = self
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.delegate = self
            controller.searchBar.frame = searchFrame
            controller.searchBar.backgroundColor = UIColor(netHex:0x2E2E2E)
            controller.searchBar.placeholder = "search                                  "
            
            //searchbar textfield design
            let textFieldInsideSearchBar = controller.searchBar.valueForKey("searchField") as? UITextField
            textFieldInsideSearchBar?.backgroundColor = UIColor(netHex:0x2E2E2E)
            textFieldInsideSearchBar?.textColor = UIColor(netHex:0xECF0F1)
            textFieldInsideSearchBar?.font = UIFont.systemFontOfSize(16.0)
            textFieldInsideSearchBar?.keyboardAppearance = .Dark
            return controller
        })()
        searchContainer.addSubview(resultSearchController.searchBar)
        
        //button displays
        displaySafariButton()
        displayHistoryButton()
        displayBookmarkButton()
        displaySettingsButton()
        displayAboutButton()
        displayNewtabButton()
    }
    
    deinit{
        if let superView = resultSearchController.view.superview
        {
            superView.removeFromSuperview()
        }
    }
    
    //windows management functions
    override func viewDidAppear(animated: Bool) {
        //added observer for showing about screen
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SlideViewController.reloadTable(_:)), name: "tableReloadNotify", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SlideViewController.reloadWindowView(_:)), name: "windowViewReload", object: nil)
        
        navBar.frame.origin.x = -55 //set original navigation bar origin
        trashButton = false
        slideUpdate = false
        
        //set Toast alert style
        style.messageColor = UIColor(netHex: 0x2E2E2E)
        style.backgroundColor = UIColor(netHex:0xECF0F1)
        ToastManager.shared.style = style
        
        //get value from struct variable
        tempArray_title = slideViewValue.windowStoreTitle
        
        //reset mainView variable for deleting all feature
        mainView = 1
        
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
        
        //reset bookmark button
        bkButton.setImage(UIImage(named: "Bookmark"), forState: UIControlState.Normal)
        slideViewValue.bkButtonSwitch = false
    }
    
    override func viewDidDisappear(animated: Bool) {
        resultSearchController.active = false
        trashBut.enabled = true
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        //reset to original Toast alert style
        style.messageColor = UIColor(netHex: 0xECF0F1)
        style.backgroundColor = UIColor(netHex:0x444444)
        ToastManager.shared.style = style
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    //recognize tap gesture recognizer when touch is not at index path of window view
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            let location = touch.locationInView(windowView)
            return (windowView.indexPathForRowAtPoint(location) == nil)
        }
        return true
    }
    
    func onTapPress(gestureRecognizer:UIGestureRecognizer){
        resultSearchController.searchBar.endEditing(true)
    }
    
    func didPresentSearchController(searchController: UISearchController) {
        searchController.searchBar.showsCancelButton = false
        searchController.searchBar.frame = searchFrame
    }
    
    //filter user input
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filteredTableData.removeAll(keepCapacity: false)
        
        //hide navBar
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.navBar.frame.origin.x = -55
            }, completion: { finished in
        })
        trashButton = false
        
        trashBut.enabled = false
        
        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (tempArray_title as NSArray).filteredArrayUsingPredicate(searchPredicate)
        filteredTableData = array as! [String]
        
        windowView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, windowView.numberOfSections)), withRowAnimation: .Fade)
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        if(searchBar.text == "") { //redisplay table data if search bar is nil
            resultSearchController.active = false
            trashBut.enabled = true
        }
    }
    
    //function to reload the table content from another class
    func reloadWindowView(notification: NSNotification) {
        if (mainView == 1) && (slideUpdate == false) {
            tempArray_title = slideViewValue.windowStoreTitle
            windowView.reloadData()
        } else if (mainView == 2) && (slideUpdate == false) {
            tempArray_title = slideViewValue.likesTitle
            windowView.reloadData()
        }
    }
    
    //function to toggle reveal controller from another class
    func reloadTable(notification: NSNotification) {
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    func scrollLastestTab(animate: Bool) {
        //scroll the tableView to display the current tab
        let indexPath = NSIndexPath(forRow: slideViewValue.windowCurTab, inSection: (windowView.numberOfSections-1))
        windowView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: animate)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(resultSearchController.active) {
            return filteredTableData.count
        } else {
            return tempArray_title.count
        }
    }
    
    //design of different cells
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("programmaticCell") as! MGSwipeTableCell!
        if cell == nil {
            cell = MGSwipeTableCell(style: .Subtitle, reuseIdentifier: "programmaticCell")
        }
        
        //shorten the website title
        var titleName = ""
        if(resultSearchController.active) {
            titleName = filteredTableData[indexPath.row]
        } else {
            titleName = tempArray_title[indexPath.row]
        }
        if(titleName == "") {
            titleName = "untitled"
        }
        cell.textLabel?.text = "                " + titleName
        if mainView == 0 {
            cell.detailTextLabel?.text = "                    " + slideViewValue.historyUrl[indexPath.row]
        } else if mainView == 2 {
            cell.detailTextLabel?.text = "                    " + slideViewValue.likesUrl[indexPath.row]
        } else if mainView == 1 {
            cell.detailTextLabel?.text = "                    " + slideViewValue.windowStoreUrl[indexPath.row]
        }
        cell.textLabel?.font = UIFont.systemFontOfSize(16.0)
        cell.detailTextLabel!.font = UIFont.systemFontOfSize(12.0)
        cell.delegate = self
        
        //cell design
        if(indexPath.row == slideViewValue.windowCurTab) && (mainView == 1) {
            cell.backgroundColor = slideViewValue.windowCurColour
        }
        else {
            cell.backgroundColor = UIColor(netHex:0x333333)
        }
        cell.textLabel?.textColor = UIColor(netHex: 0xECF0F1)
        cell.detailTextLabel?.textColor = UIColor(netHex: 0xECF0F1)
        cell.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
    
        //configure right buttons
        if (mainView == 0) || (mainView == 1) {
            cell.rightButtons = [MGSwipeButton(title: "Close", backgroundColor: UIColor(netHex:0xE74C3C), callback: {
                (sender: MGSwipeTableCell!) -> Bool in
                self.tabDeleteActions(indexPath.row)
            }), MGSwipeButton(title: setLikesText(indexPath.row), backgroundColor: UIColor(netHex:0xF1C40F), callback: {
                (sender: MGSwipeTableCell!) -> Bool in
                self.tabLikeActions(indexPath.row, likes: self.setLikesText(indexPath.row))
            })]
        } else {
            cell.rightButtons = [MGSwipeButton(title: "Close", backgroundColor: UIColor(netHex:0xE74C3C), callback: {
                (sender: MGSwipeTableCell!) -> Bool in
                self.tabDeleteActions(indexPath.row)
            })]
        }
        cell.rightSwipeSettings.transition = MGSwipeTransition.Static
        cell.rightExpansion.buttonIndex = 0
        cell.rightExpansion.fillOnTrigger = true
        
        return cell
    }
    
    func swipeTableCellWillBeginSwiping(cell: MGSwipeTableCell!) {
        slideUpdate = true
        resultSearchController.searchBar.endEditing(true)
    }
    
    func swipeTableCellWillEndSwiping(cell: MGSwipeTableCell!) {
        slideUpdate = false
        if mainView == 1 {
            tempArray_title = slideViewValue.windowStoreTitle
            windowView.reloadData()
        } else if mainView == 2 {
            tempArray_title = slideViewValue.likesTitle
            windowView.reloadData()
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        resultSearchController.searchBar.endEditing(true)
    }
    
    //function to set likeText if user did like
    func setLikesText(cell_row: Int) -> String {
        var likeText: String = ""
        
        if mainView == 1 {
            if slideViewValue.likesUrl.contains(slideViewValue.windowStoreUrl[cell_row]) {
                likeText = "Unlike"
            } else {
                likeText = "Like"
            }
        }
        if mainView == 0 {
            if slideViewValue.likesUrl.contains(slideViewValue.historyUrl[cell_row]) {
                likeText = "Unlike"
            } else {
                likeText = "Like"
            }
        }
        
        return likeText
    }
    
    //actions of the cells
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        //reset readActions
        slideViewValue.readActions = false
        slideViewValue.readRecover = false
        slideViewValue.readActionsCheck = false
        
        if mainView == 1 { //normal changing tabs
            if(slideViewValue.windowCurTab != indexPath.row) { //open link if user not touch current tab, else not loading
                slideViewValue.scrollPositionSwitch = true
                slideViewValue.windowCurTab = indexPath.row
                //open stored urls
                WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL: NSURL(string: slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 15))
            }
        }
        if mainView == 0 { //use History feature
            if(slideViewValue.windowStoreUrl[slideViewValue.windowCurTab] != "about:blank") {
                slideViewValue.windowCurTab = slideViewValue.windowCurTab + 1
                slideViewValue.windowStoreTitle.insert(slideViewValue.historyTitle[indexPath.row], atIndex: slideViewValue.windowCurTab)
                slideViewValue.windowStoreUrl.insert(slideViewValue.historyUrl[indexPath.row], atIndex: slideViewValue.windowCurTab)
                slideViewValue.scrollPosition.insert("0.0", atIndex: slideViewValue.windowCurTab)
                //open stored urls
                WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL: NSURL(string: slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 15))
            }
            else {
                //open stored urls
                WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL: NSURL(string: slideViewValue.historyUrl[indexPath.row])!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 15))
            }
        }
        if mainView == 2 { //use Bookmark feature
            if(slideViewValue.windowStoreUrl[slideViewValue.windowCurTab] != "about:blank") {
                slideViewValue.windowCurTab = slideViewValue.windowCurTab + 1
                slideViewValue.windowStoreTitle.insert(slideViewValue.likesTitle[indexPath.row], atIndex: slideViewValue.windowCurTab)
                slideViewValue.windowStoreUrl.insert(slideViewValue.likesUrl[indexPath.row], atIndex: slideViewValue.windowCurTab)
                slideViewValue.scrollPosition.insert("0.0", atIndex: slideViewValue.windowCurTab)
                //open stored urls
                WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL: NSURL(string: slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 15))
            }
            else {
                //open stored urls
                WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL: NSURL(string: slideViewValue.likesUrl[indexPath.row])!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 15))
            }
        }
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    //function to like tabs
    func tabLikeActions(cell_row: Int, likes: String) -> Bool {
        if(likes == "Like") {
            if mainView == 1 {
                slideViewValue.likesTitle.append(slideViewValue.windowStoreTitle[cell_row])
                slideViewValue.likesUrl.append(slideViewValue.windowStoreUrl[cell_row])
            } else if mainView == 0 {
                slideViewValue.likesTitle.append(slideViewValue.historyTitle[cell_row])
                slideViewValue.likesUrl.append(slideViewValue.historyUrl[cell_row])
            }
        } else if(likes == "Unlike") {
            //Unlike; Get index first, then remove...
            if mainView == 1 {
                if let i = slideViewValue.likesUrl.indexOf(slideViewValue.windowStoreUrl[cell_row]) {
                    slideViewValue.likesTitle.removeAtIndex(i)
                    slideViewValue.likesUrl.removeAtIndex(i)
                }
            } else if mainView == 0 {
                if let i = slideViewValue.likesUrl.indexOf(slideViewValue.historyUrl[cell_row]) {
                    slideViewValue.likesTitle.removeAtIndex(i)
                    slideViewValue.likesUrl.removeAtIndex(i)
                }
            }
        }
        windowView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, windowView.numberOfSections)), withRowAnimation: .Fade)
        return true
    }
    
    //function to delete tabs
    func tabDeleteActions(cell_row: Int) -> Bool {
        //LOGICs of removing tabs
        if(mainView == 1) { //normal mode
            if(tempArray_title.count > 1) {
                if(slideViewValue.windowCurTab != cell_row) {
                    tempArray_title.removeAtIndex(cell_row)
                    slideViewValue.windowStoreUrl.removeAtIndex(cell_row)
                    slideViewValue.scrollPosition.removeAtIndex(cell_row)
                    if(cell_row < slideViewValue.windowCurTab) {
                        slideViewValue.windowCurTab -= 1
                    }
                    slideViewValue.windowStoreTitle = tempArray_title
                    NSNotificationCenter.defaultCenter().postNotificationName("updateWindow", object: nil)
                }
                else {
                    if(slideViewValue.windowCurTab == (tempArray_title.count - 1)) {
                        tempArray_title.removeAtIndex(cell_row)
                        slideViewValue.windowStoreUrl.removeAtIndex(cell_row)
                        slideViewValue.scrollPosition.removeAtIndex(cell_row)
                    }
                    else {
                        tempArray_title.removeAtIndex(cell_row)
                        slideViewValue.windowStoreUrl.removeAtIndex(cell_row)
                        slideViewValue.scrollPosition.removeAtIndex(cell_row)
                    }
                    if(slideViewValue.windowCurTab != 0) {
                        slideViewValue.windowCurTab -= 1
                    }
                    slideViewValue.windowStoreTitle = tempArray_title
                    
                    //reset readActions
                    slideViewValue.readActions = false
                    slideViewValue.readRecover = false
                    slideViewValue.readActionsCheck = false
                    
                    sgButton.setImage(UIImage(named: "Read"), forState: UIControlState.Normal)
                    
                    //open tabs in background
                    WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL: NSURL(string: slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 15))
                    slideViewValue.scrollPositionSwitch = true
                }
            }
            else if(tempArray_title.count == 1) {
                slideViewValue.windowStoreUrl[0] = "about:blank"
                tempArray_title[0] = ""
                slideViewValue.windowStoreTitle = tempArray_title
                slideViewValue.scrollPosition[0] = "0.0"
                
                //reset readActions
                slideViewValue.readActions = false
                slideViewValue.readRecover = false
                slideViewValue.readActionsCheck = false
                
                sgButton.setImage(UIImage(named: "Read"), forState: UIControlState.Normal)
                
                //open tabs in background
                WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL:NSURL(string: "about:blank")!))
                slideViewValue.scrollPositionSwitch = true
                revealViewController().rightRevealToggleAnimated(true)
            }
        }
        else if(mainView == 0) { //"history" mode
            tempArray_title.removeAtIndex(cell_row)
            slideViewValue.historyUrl.removeAtIndex(cell_row)
            slideViewValue.historyDate.removeAtIndex(cell_row)
            slideViewValue.historyTitle = tempArray_title
            if(tempArray_title.count == 0) { //switch off history while history is empty
                historyBackToNormal()
                view.makeToast("History is empty...", duration: 0.8, position: CGPoint(x: view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70)) //alert user
            }
        }
        else if(mainView == 2) { //"likes" mode
            tempArray_title.removeAtIndex(cell_row)
            slideViewValue.likesUrl.removeAtIndex(cell_row)
            slideViewValue.likesTitle = tempArray_title
            if(tempArray_title.count == 0) { //switch off likes while bookmark is empty
                bookmarkBackToNormal()
                view.makeToast("You didn't like any...", duration: 0.8, position: CGPoint(x: view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70)) //alert user instead of switching to bookmarks
            }
        }
        windowView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, windowView.numberOfSections)), withRowAnimation: .Fade)
        return true
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
        //reset readActions
        slideViewValue.readActions = false
        slideViewValue.readRecover = false
        slideViewValue.readActionsCheck = false
        
        //open new tab
        slideViewValue.windowCurTab = slideViewValue.windowCurTab + 1
        slideViewValue.windowStoreTitle.insert("", atIndex: slideViewValue.windowCurTab)
        slideViewValue.windowStoreUrl.insert("about:blank", atIndex: slideViewValue.windowCurTab)
        slideViewValue.scrollPosition.insert("0.0", atIndex: slideViewValue.windowCurTab)
        
        WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL:NSURL(string: slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])!))
        
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    func aboutAction() {
        slideViewValue.alertPopup(1, message: "") //show about message popup
    }
    
    func safariAction() {
        UIApplication.sharedApplication().openURL(NSURL(string: slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])!)
        revealViewController().rightRevealToggleAnimated(true)
    }
    
    func historyAction() {
        resultSearchController.active = false
        trashBut.enabled = true
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.navBar.frame.origin.x = -55
            }, completion: { finished in
        })
        trashButton = false
        
        if(slideViewValue.htButtonSwitch == false) {
            if(slideViewValue.historyTitle.count > 0) { //avoid size < 0 bug crash
                htButton.setImage(UIImage(named: "History-filled"), forState: UIControlState.Normal)
                slideViewValue.htButtonSwitch = true
                bkButton.setImage(UIImage(named: "Bookmark"), forState: UIControlState.Normal)
                slideViewValue.bkButtonSwitch = false
                bgText.text = "history"
                tempArray_title = slideViewValue.historyTitle
                mainView = 0
                windowView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, windowView.numberOfSections)), withRowAnimation: .Fade)
                view.makeToast("History", duration: 0.8, position: CGPoint(x: view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70))
                
                //scroll the tableView to display the latest tab
                let indexPath = NSIndexPath(forRow: windowView.numberOfRowsInSection(windowView.numberOfSections-1)-1, inSection: (windowView.numberOfSections-1))
                windowView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            } else {
                view.makeToast("History is empty...", duration: 0.8, position: CGPoint(x: view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70)) //alert user instead of switching to History
            }
        }
        else {
            historyBackToNormal()
            view.makeToast("Tabs", duration: 0.8, position: CGPoint(x: view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70))
        }
    }
    
    func historyBackToNormal() { //switch History feature off
        htButton.setImage(UIImage(named: "History"), forState: UIControlState.Normal)
        slideViewValue.htButtonSwitch = false
        bgText.text = "maccha"
        tempArray_title = slideViewValue.windowStoreTitle
        mainView = 1
        windowView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, windowView.numberOfSections)), withRowAnimation: .Fade)
        scrollLastestTab(true)
    }
    
    func bookmarkAction() {
        resultSearchController.active = false
        trashBut.enabled = true
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.navBar.frame.origin.x = -55
            }, completion: { finished in
        })
        trashButton = false
        
        if(slideViewValue.bkButtonSwitch == false) {
            if(slideViewValue.likesTitle.count > 0) { //avoid size < 0 bug crash
                bkButton.setImage(UIImage(named: "Bookmark-filled"), forState: UIControlState.Normal)
                slideViewValue.bkButtonSwitch = true
                htButton.setImage(UIImage(named: "History"), forState: UIControlState.Normal)
                slideViewValue.htButtonSwitch = false
                bgText.text = "likes"
                tempArray_title = slideViewValue.likesTitle
                mainView = 2
                windowView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, windowView.numberOfSections)), withRowAnimation: .Fade)
                view.makeToast("Likes", duration: 0.8, position: CGPoint(x: view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70))
                
                //scroll the tableView to display the latest tab
                let indexPath = NSIndexPath(forRow: windowView.numberOfRowsInSection(windowView.numberOfSections-1)-1, inSection: (windowView.numberOfSections-1))
                windowView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            } else {
                view.makeToast("You didn't like any...", duration: 0.8, position: CGPoint(x: view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70)) //alert user instead of switching to bookmarks
            }
        }
        else {
            bookmarkBackToNormal()
            view.makeToast("Tabs", duration: 0.8, position: CGPoint(x: view.frame.size.width-120, y: UIScreen.mainScreen().bounds.height-70))
        }
    }
    
    func bookmarkBackToNormal() { //switch Bookmark feature off
        bkButton.setImage(UIImage(named: "Bookmark"), forState: UIControlState.Normal)
        slideViewValue.bkButtonSwitch = false
        bgText.text = "maccha"
        tempArray_title = slideViewValue.windowStoreTitle
        mainView = 1
        windowView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, windowView.numberOfSections)), withRowAnimation: .Fade)
        scrollLastestTab(true)
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

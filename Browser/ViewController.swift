/*
*  ViewController.swift
*  Maccha Browser
*
*  This Source Code Form is subject to the terms of the Mozilla Public
*  License, v. 2.0. If a copy of the MPL was not distributed with this
*  file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*  Created by Jason Wong on 28/01/2016.
*  Copyright © 2016 Studios Pâtes, Jason Wong (mail: jasonkwh@gmail.com).
*/

import UIKit
import AudioToolbox
import RealmSwift

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate, SWRevealViewControllerDelegate, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var mask: UIView!
    @IBOutlet weak var barView: UIView!
    @IBOutlet weak var windowView: UIButton!
    @IBOutlet weak var refreshStopButton: UIButton!
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var bar: UIToolbar!
    var moveToolbar: Bool = false
    var moveToolbarShown: Bool = false
    var moveToolbarReturn: Bool = false
    var webAddress: String = ""
    var webTitle: String = ""
    var toolbarStyle: Int = 0
    var scrollDirectionDetermined: Bool = false
    var scrollMakeStatusBarDown: Bool = false
    var google: String = "https://www.google.com"
    var tempUrl: String = ""
    var pbString: String = ""
    var activity:NSUserActivity = NSUserActivity(activityType: "com.studiospates.maccha.handsoff") //handoff listener
    var continuedActivity: NSUserActivity?
    var touchPoint: CGPoint = CGPointZero
    
    //remember previous scrolling position~~
    let panPressRecognizer = UIPanGestureRecognizer()
    var scrollPositionRecord: Bool = false //user tap, record scroll position
    
    //actionsheet
    var longPressRecognizer = UILongPressGestureRecognizer()
    var longPressSwitch: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        //Inject safari-reader.js, and initialise the wkwebview
        let path_reader = NSBundle.mainBundle().pathForResource("safari-reader", ofType: "js")
        let script = try! String(contentsOfFile: path_reader!, encoding: NSUTF8StringEncoding)
        let userScript = WKUserScript(source: script, injectionTime: .AtDocumentEnd, forMainFrameOnly: false)
        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        WKWebviewFactory.sharedInstance.webView = WKWebView(frame: CGRectZero, configuration: configuration)
        super.init(coder: aDecoder)
        
        WKWebviewFactory.sharedInstance.webView.navigationDelegate = self
        WKWebviewFactory.sharedInstance.webView.UIDelegate = self
        WKWebviewFactory.sharedInstance.webView.scrollView.delegate = self
        
        //use AFNetworking module to set NSURLCache
        let manager = AFHTTPSessionManager()
        manager.requestSerializer.cachePolicy = NSURLRequestCachePolicy.ReturnCacheDataElseLoad
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        //Splash Screen
        let splashView: CBZSplashView = CBZSplashView(icon: UIImage(named: "Tea"), backgroundColor: UIColor(netHex:0x70BF41))
        self.view.addSubview(splashView)
        splashView.startAnimation()
        
        //register observer for willEnterForeground / willEnterBackground state
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.applicationWillEnterBackground(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.windowUpdate(_:)), name: "updateWindow", object: nil)
        
        self.revealViewController().delegate = self
        if self.revealViewController() != nil {
            revealViewController().rightViewRevealWidth = 240
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        mask.backgroundColor = UIColor.blackColor()
        mask.alpha = 0
        view.layer.cornerRadius = 5 //set corner radius of uiview
        view.layer.masksToBounds = true
        
        addToolBar(urlField)
        definesUrlfield() //setup urlfield style
        displayRefreshOrStop() //display refresh or change to stop while loading...
        loadRealmData()
        
        if(slideViewValue.newUser == 0) {
            //set original homepage at index 0 of store array
            slideViewValue.windowStoreTitle = ["Google"]
            slideViewValue.windowStoreUrl = [google]
            slideViewValue.scrollPosition = ["0.0"]
            slideViewValue.newUser = 1
        }
        
        //display current window number on the window button
        displayCurWindowNum(slideViewValue.windowStoreTitle.count)
        
        //set toolbar color and style
        bar.clipsToBounds = true
        toolbarColor(toolbarStyle)
        
        //set Toast alert style
        var style = ToastStyle()
        style.messageColor = UIColor(netHex: 0xECF0F1)
        style.backgroundColor = UIColor(netHex:0x444444)
        ToastManager.shared.style = style
        
        WKWebviewFactory.sharedInstance.webView.snapshotViewAfterScreenUpdates(true) //snapshot webview after loading new screens
        self.navigationController?.navigationBarHidden = true //hide navigation bar
        
        //hook the tap press event
        panPressRecognizer.delegate = self
        panPressRecognizer.addTarget(self, action: #selector(ViewController.onPanPress(_:)))
        WKWebviewFactory.sharedInstance.webView.scrollView.addGestureRecognizer(panPressRecognizer)
        
        //long press to show the action sheet
        longPressRecognizer.delegate = self
        longPressRecognizer.addTarget(self, action: #selector(ViewController.onLongPress(_:)))
        WKWebviewFactory.sharedInstance.webView.scrollView.addGestureRecognizer(longPressRecognizer)
        
        //user agent string
        let ver:String = "Kapiko/4.0 Maccha/" + slideViewValue.version()
        WKWebviewFactory.sharedInstance.webView.performSelector(Selector("_setApplicationNameForUserAgent:"), withObject: ver)
        
        WKWebviewFactory.sharedInstance.webView.allowsBackForwardNavigationGestures = true //enable Back & Forward gestures
        barView.frame = CGRect(x:0, y: 0, width: view.frame.width, height: 30)
        view.insertSubview(WKWebviewFactory.sharedInstance.webView, belowSubview: progressView)
        WKWebviewFactory.sharedInstance.webView.translatesAutoresizingMaskIntoConstraints = false
        let height = NSLayoutConstraint(item: WKWebviewFactory.sharedInstance.webView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: -44)
        let width = NSLayoutConstraint(item: WKWebviewFactory.sharedInstance.webView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
        view.addConstraints([height, width])
        
        WKWebviewFactory.sharedInstance.webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
        WKWebviewFactory.sharedInstance.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
        
        backButton.enabled = false
        forwardButton.enabled = false
        
        if(slideViewValue.shortcutItem == 0) {
            if(slideViewValue.newUser == 0) {
                loadRequest(slideViewValue.windowStoreUrl[0])
            } else {
                if(slideViewValue.windowStoreUrl[slideViewValue.windowCurTab] == "about:blank") {
                    loadRequest("about:blank")
                } else {
                    slideViewValue.scrollPositionSwitch = false
                    loadRequest(slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])
                }
            }
        }
        else {
            let pb: UIPasteboard = UIPasteboard.generalPasteboard()
            if(pb.string == nil) {
                pbString = ""
            } else {
                pbString = pb.string!
            }
            if((slideViewValue.shortcutItem == 1) || ((slideViewValue.shortcutItem == 2) && (pbString != ""))){
                openShortcutItem()
            }
            if((slideViewValue.shortcutItem == 2) && (pbString == "")) {
                loadRequest(slideViewValue.windowStoreUrl[slideViewValue.windowStoreTitle.count-1])
                slideViewValue.alertPopup(0, message: "Clipboard is empty")
            }
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //Load data from Realm database
    func loadRealmData() {
        for wdata in realm_maccha.objects(WkData) {
            slideViewValue.windowStoreTitle = wdata.wk_title
            slideViewValue.windowStoreUrl = wdata.wk_url
            slideViewValue.scrollPosition = wdata.wk_scrollPosition
        }
        for gdata in realm_maccha.objects(GlobalData) {
            slideViewValue.searchEngines = gdata.search
            slideViewValue.windowCurTab = gdata.current_tab
            slideViewValue.newUser = gdata.new_user
        }
        for htdata in realm_maccha.objects(HistoryData) {
            slideViewValue.historyTitle = htdata.history_title
            slideViewValue.historyUrl = htdata.history_url
        }
    }
    
    //Determine quick actions...
    func openShortcutItem() {
        //reset readActions
        slideViewValue.readActions = false
        slideViewValue.readRecover = false
        slideViewValue.readActionsCheck = false
        slideViewValue.windowStoreTitle.append("")
        slideViewValue.windowStoreUrl.append("about:blank")
        slideViewValue.scrollPosition.append("0.0")
        slideViewValue.windowCurTab = slideViewValue.windowStoreTitle.count - 1
        windowView.setTitle(String(slideViewValue.windowStoreTitle.count), forState: UIControlState.Normal)
        if(slideViewValue.shortcutItem == 1) {
            loadRequest("about:blank")
        }
        else if(slideViewValue.shortcutItem == 2) {
            //Open URL from clipboard
            loadRequest(pbString)
            slideViewValue.windowStoreTitle[slideViewValue.windowCurTab] = WKWebviewFactory.sharedInstance.webView.title!
            slideViewValue.windowStoreUrl[slideViewValue.windowCurTab] = (WKWebviewFactory.sharedInstance.webView.URL?.absoluteString)!
        }
        slideViewValue.shortcutItem = 0
    }
    
    //function to update windows count from another class
    func windowUpdate(notification: NSNotification) {
        windowView.setTitle(String(slideViewValue.windowStoreTitle.count), forState: UIControlState.Normal)
    }
    
    //actions those the app going to do when the app enters foreground
    func applicationWillEnterForeground(notification: NSNotification) {
        let pb: UIPasteboard = UIPasteboard.generalPasteboard()
        if(pb.string == nil) {
            pbString = ""
        } else {
            pbString = pb.string!
        }
        if((slideViewValue.shortcutItem == 1) || ((slideViewValue.shortcutItem == 2) && (pbString != ""))){
            openShortcutItem()
        }
        if((slideViewValue.shortcutItem == 2) && (pbString == "")) {
            slideViewValue.alertPopup(0, message: "Clipboard is empty")
        }
    }
    
    //actions those the app going to do when the app enters background
    func applicationWillEnterBackground(notification: NSNotification) {
        
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func onPanPress(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            scrollPositionRecord = true
        }
        if gestureRecognizer.state == UIGestureRecognizerState.Ended {
            scrollPositionRecord = false
        }
    }
    
    func onLongPress(gestureRecognizer:UIGestureRecognizer){
        touchPoint = gestureRecognizer.locationInView(self.view)
        longPressSwitch = true
    }

    //function to hide the statusbar
    func hideStatusbar() {
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
    }
    
    //function to show the statusbar
    func showStatusbar() {
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
    }
    
    //detect the right reveal view is toggle, and do some actions...
    func revealController(revealController: SWRevealViewController!, willMoveToPosition position: FrontViewPosition) {
        if revealController.frontViewPosition == FrontViewPosition.Left
        {
            hideKeyboard()
            hideStatusbar()
            WKWebviewFactory.sharedInstance.webView.userInteractionEnabled = false
            self.bar.userInteractionEnabled = false
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.mask.alpha = 0.6
                }, completion: { finished in
            })
        }
        else
        {
            windowView.setTitle(String(slideViewValue.windowStoreTitle.count), forState: UIControlState.Normal)
            WKWebviewFactory.sharedInstance.webView.userInteractionEnabled = true
            self.bar.userInteractionEnabled = true
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.mask.alpha = 0
                }, completion: { finished in
            })
            if(slideViewValue.cellActions == true) {
                //open stored urls
                if(slideViewValue.htButtonSwitch == false) {
                    loadRequest(slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])
                    slideViewValue.scrollPositionSwitch = true
                }
                else if(slideViewValue.htButtonSwitch == true) {
                    //open history entry
                    if(webAddress == "about:blank") {
                        loadRequest(slideViewValue.historyUrl[slideViewValue.htButtonIndex])
                    } else {
                        loadRequest(slideViewValue.historyUrl[slideViewValue.htButtonIndex])
                        slideViewValue.windowStoreTitle.append(WKWebviewFactory.sharedInstance.webView.title!)
                        slideViewValue.windowStoreUrl.append((WKWebviewFactory.sharedInstance.webView.URL?.absoluteString)!)
                        
                        //initial y point
                        slideViewValue.scrollPosition.append("0.0")
                        
                        slideViewValue.windowCurTab = slideViewValue.windowStoreTitle.count - 1
                    }
                    slideViewValue.scrollPositionSwitch = false
                }
                //reset readActions
                slideViewValue.readActions = false
                slideViewValue.readRecover = false
                slideViewValue.readActionsCheck = false
                slideViewValue.cellActions = false
            }
            if((slideViewValue.readActions == true) && (slideViewValue.readRecover == false)) {
                if(slideViewValue.readActionsCheck == false) {
                    tempUrl = webAddress //tempUrl updates only once...
                }
                WKWebviewFactory.sharedInstance.webView.evaluateJavaScript("var ReaderArticleFinderJS = new ReaderArticleFinder(document);") { (obj, error) -> Void in
                }
                WKWebviewFactory.sharedInstance.webView.evaluateJavaScript("var article = ReaderArticleFinderJS.findArticle();") { (html, error) -> Void in
                }
                WKWebviewFactory.sharedInstance.webView.evaluateJavaScript("article.element.innerText") { (res, error) -> Void in
                    //if let html = res as? String {
                        //self.webView.loadHTMLString(html, baseURL: nil)
                    //}
                }
                WKWebviewFactory.sharedInstance.webView.evaluateJavaScript("article.element.outerHTML") { (res, error) -> Void in
                    if let html = res as? String {
                        if(slideViewValue.readActionsCheck == false) {
                            WKWebviewFactory.sharedInstance.webView.loadHTMLString("<body style='font-family: -apple-system; font-family: '-apple-system','HelveticaNeue';'><meta name = 'viewport' content = 'user-scalable=no, width=device-width'>" + html, baseURL: nil)
                        }
                    }
                }
                WKWebviewFactory.sharedInstance.webView.evaluateJavaScript("ReaderArticleFinderJS.isReaderModeAvailable();") { (html, error) -> Void in
                    if(String(html) == "Optional(0)") {
                        if(slideViewValue.readActionsCheck == false) {
                            //this avoids alert popups while hiding the slideViewController (although the user did not press the read button)
                            slideViewValue.alertPopup(0, message: "Reader mode is not available for this page")
                            slideViewValue.readActions = false //disable readbility
                        }
                    }
                    else {
                        slideViewValue.readActionsCheck = true //turns on the boolean switch on to avoid alert popups
                    }
                }
                WKWebviewFactory.sharedInstance.webView.evaluateJavaScript("ReaderArticleFinderJS.prepareToTransitionToReader();") { (html, error) -> Void in
                }
            }
            if((slideViewValue.readActions == true) && (slideViewValue.readRecover == true)) {
                //load contents by wkwebview
                loadRequest(tempUrl)
                slideViewValue.readActionsCheck = false //reset
                slideViewValue.readRecover = false
            }
        }
    }
    
    //scroll down to hide status bar, scroll up to show status bar, with animations
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //store current scroll positions to array
        if(scrollPositionRecord == true) {
            slideViewValue.scrollPosition[slideViewValue.windowCurTab] = scrollView.contentOffset.y.description
        }
        
        if !scrollDirectionDetermined {
            if(moveToolbar == false) {
                let translation = scrollView.panGestureRecognizer.translationInView(self.view)
                if translation.y > 0 {
                    showStatusbar()
                    scrollDirectionDetermined = true
                    scrollMakeStatusBarDown = true
                }
                else if translation.y < 0 {
                    hideStatusbar()
                    scrollDirectionDetermined = true
                    scrollMakeStatusBarDown = false
                }
            }
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollDirectionDetermined = false
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollDirectionDetermined = false
    }
    
    override func canResignFirstResponder() -> Bool {
        return true
    }
    
    //shake to change toolbar color, phone will vibrate for confirmation
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == .MotionShake {
            /*if(toolbarStyle < 1) {
                toolbarStyle++
            }
            else {
                toolbarStyle = 0
            }
            toolbarColor(toolbarStyle)*/
            refreshPressed()
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    //function of setting toolbar color
    func toolbarColor(colorID: Int) {
        switch colorID {
        case 0:
            //Green
            progressView.tintColor = UIColor(netHex:0x00882B)
            urlField.backgroundColor = UIColor(netHex:0x00882B)
            bar.barTintColor = UIColor(netHex:0x70BF41)
            slideViewValue.windowCurColour = UIColor(netHex:0x70BF41)
        case 1:
            //Blue
            progressView.tintColor = UIColor(netHex:0x0153A4)
            urlField.backgroundColor = UIColor(netHex:0x0153A4)
            bar.barTintColor = UIColor(netHex:0x499AE7)
            slideViewValue.windowCurColour = UIColor(netHex:0x499AE7)
        default:
            break
        }
    }
    
    //function which defines the clear button of the urlfield and some characteristics of urlfield
    func definesUrlfield() {
        //changes scales exclusively for iPhone 6 Plus or iPhone 6s Plus
        /*if((UIDevice.currentDevice().modelName == "iPhone 6 Plus") || (UIDevice.currentDevice().modelName == "iPhone 6s Plus") || (UIDevice.currentDevice().modelName == "Simulator")) {
            urlField.frame.size.width = 208
        }*/
        urlField.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        urlField.clipsToBounds = true
        let crButton = UIButton(type: UIButtonType.System)
        crButton.setImage(UIImage(named: "Clear"), forState: UIControlState.Normal)
        crButton.addTarget(self, action: #selector(ViewController.clearPressed), forControlEvents: UIControlEvents.TouchUpInside)
        crButton.imageEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 5)
        crButton.frame = CGRectMake(0, 0, 15, 15)
        urlField.rightViewMode = .WhileEditing
        urlField.rightView = crButton
    }
    
    //function to display current window number in the window button
    func displayCurWindowNum(currentNum: Int) {
        windowView.setBackgroundImage(UIImage(named: "Window"), forState: UIControlState.Normal)
        windowView.setTitle(String(currentNum), forState: UIControlState.Normal)
        windowView.addTarget(revealViewController(), action: #selector(SWRevealViewController.rightRevealToggle(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        windowView.frame = CGRectMake(0, 0, 30, 30)
    }
    
    //function to display refresh or change to stop while loading...
    func displayRefreshOrStop() {
        refreshStopButton.setImage(UIImage(named: "Refresh"), forState: UIControlState.Normal)
        refreshStopButton.addTarget(self, action: #selector(ViewController.refreshPressed), forControlEvents: UIControlEvents.TouchUpInside)
        refreshStopButton.imageEdgeInsets = UIEdgeInsetsMake(0, -13, 0, -15)
        refreshStopButton.frame = CGRectMake(0, 0, 30, 30)
    }
    
    //keyboards related
    //show/hide keyboard reactions
    func textFieldDidBeginEditing(textField: UITextField) -> Bool {
        if textField == urlField {
            moveToolbar = true; //move toolbar as the keyboard moves
            
            //display urls in urlfield
            if(moveToolbarShown == false) {
                urlField.textAlignment = .Left
                if(slideViewValue.readActions == true) {
                    urlField.text = tempUrl
                }
                else {
                    if(webAddress != "about:blank") {
                        urlField.text = webAddress
                    } else {
                        urlField.text = ""
                    }
                }
            }
            return true //urlField
        }
        else {
            return false
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.navigationBarHidden = true //hide navigation bar
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBarHidden = true //hide navigation bar
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    //auto show toolbar while editing
    func keyboardWillShow(sender: NSNotification) {
        if(moveToolbar == true) {
            moveToolbarShown = true
            if let userInfo = sender.userInfo {
                if let keyboardHeight = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.origin.y {
                    let keyboardHeight2 = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size.height
                    var keyHeight = keyboardHeight-self.view.frame.size.height
                    if(((keyboardHeight-self.view.frame.size.height) > (-keyboardHeight2!)) && ((UIDevice.currentDevice().modelName.containsString("iPhone")) || (UIDevice.currentDevice().modelName.containsString("iPod")))) {
                        keyHeight = -keyboardHeight2!
                    }
                    self.view.frame.origin.y = keyHeight
                    UIView.animateWithDuration(0.10, animations: { () -> Void in
                        self.view.layoutIfNeeded()
                    })
                }
            }
        }
    }
    
    //auto hide toolbar while editing
    func keyboardWillHide(sender: NSNotification) {
        if(moveToolbar == true) {
            self.view.frame.origin.y = 0
            UIView.animateWithDuration(0.10, animations: { () -> Void in self.view.layoutIfNeeded() })
            moveToolbar = false
            moveToolbarShown = false
            if(moveToolbarReturn == false) {
                urlField.textAlignment = .Center
                if(slideViewValue.readActions == true) {
                    urlField.text = "Reader mode"
                } else {
                    urlField.text = webTitle
                }
            }
        }
    }
    
    //function to detect screen orientation change and do some actions
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        barView.frame = CGRect(x: 0, y: 0, width: size.width, height: 30)
        if(scrollMakeStatusBarDown == true) {
            showStatusbar()
        }
        hideKeyboard()
    }
    
    //function to define the actions of urlField.go
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        moveToolbarReturn = true
        urlField.resignFirstResponder()
        
        loadRequest(urlField.text!)
        slideViewValue.readActionsCheck = false
        
        return false
    }
    
    //function to load webview request
    func loadRequest(inputUrlAddress: String) {
        
        if(inputUrlAddress == "about:blank") {
            WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL:NSURL(string: "about:blank")!))
        } else {
            if (AFNetworkReachabilityManager.sharedManager().reachable == false) {
                slideViewValue.readActions = false //disable readbility
                
                //shorten the url by replacing http and https to null
                let shorten_url = inputUrlAddress.stringByReplacingOccurrencesOfString("https://", withString: "").stringByReplacingOccurrencesOfString("http://", withString: "").stringByReplacingOccurrencesOfString(" ", withString: "+")
                
                //check if it is URL, else use search engine
                var contents: String = ""
                let matches = matchesForRegexInText("(?i)(?:(?:https?):\\/\\/)?(?:\\S+(?::\\S*)?@)?(?:(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))|(?:(?:[a-z\\u00a1-\\uffff0-9]+-?)*[a-z\\u00a1-\\uffff0-9]+)(?:\\.(?:[a-z\\u00a1-\\uffff0-9]+-?)*[a-z\\u00a1-\\uffff0-9]+)*(?:\\.(?:[a-z\\u00a1-\\uffff]{2,})))(?::\\d{2,5})?(?:\\/[^\\s]*)?", text: ("http://" + shorten_url))
                if(matches == []) {
                    if(slideViewValue.searchEngines == 0) {
                        contents = "http://www.google.com/search?q=" + shorten_url.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
                    }
                    else if(slideViewValue.searchEngines == 1) {
                        contents = "http://www.bing.com/search?q=" + shorten_url.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
                    }
                }
                else {
                    contents = "http://" + shorten_url
                }
                
                //load contents by wkwebview
                WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL: NSURL(string: contents)!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 15))
            }
            else {
                //Popup alert window
                hideKeyboard()
                slideViewValue.alertPopup(0, message: "The Internet connection appears to be offline.")
                
                //insert a blank page if there's nothing store in the arrays
                if(slideViewValue.windowStoreTitle.count == 0) {
                    slideViewValue.windowStoreTitle.append("")
                    slideViewValue.windowStoreUrl.append("about:blank")
                    
                    //initial y point
                    slideViewValue.scrollPosition.append("0.0")
                }
            }
        }
    }
    
    //function to check url by regex
    func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matchesInString(text,
                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substringWithRange($0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    @IBAction func back(sender: UIBarButtonItem) {
        WKWebviewFactory.sharedInstance.webView.goBack()
    }
    
    @IBAction func forward(sender: UIBarButtonItem) {
        WKWebviewFactory.sharedInstance.webView.goForward()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<()>) {
        if (keyPath == "loading") {
            backButton.enabled = WKWebviewFactory.sharedInstance.webView.canGoBack
            forwardButton.enabled = WKWebviewFactory.sharedInstance.webView.canGoForward
        }
        if (keyPath == "estimatedProgress") {
            progressView.hidden = WKWebviewFactory.sharedInstance.webView.estimatedProgress == 1
            progressView.setProgress(Float(WKWebviewFactory.sharedInstance.webView.estimatedProgress), animated: true)
            
            if(Float(WKWebviewFactory.sharedInstance.webView.estimatedProgress) > 0.0) {
                //set refreshStopButton to stop state
                refreshStopButton.setImage(UIImage(named: "Stop"), forState: UIControlState.Normal)
                refreshStopButton.addTarget(self, action: #selector(ViewController.stopPressed), forControlEvents: UIControlEvents.TouchUpInside)
                
                //display current window numbers
                windowView.setTitle(String(slideViewValue.windowStoreTitle.count), forState: UIControlState.Normal)
            }
            if(Float(WKWebviewFactory.sharedInstance.webView.estimatedProgress) > 0.1) {
                //shorten url by replacing http:// and https:// to null
                let shorten_url = WKWebviewFactory.sharedInstance.webView.URL?.absoluteString.stringByReplacingOccurrencesOfString("https://", withString: "").stringByReplacingOccurrencesOfString("http://", withString: "")

                //change urlField when the page starts loading
                //display website title in the url field
                webTitle = WKWebviewFactory.sharedInstance.webView.title! //store title into webTitle for efficient use
                webAddress = shorten_url! //store address into webAddress for efficient use
                if(moveToolbar == false) {
                    urlField.textAlignment = .Center
                    if(slideViewValue.readActions == true) {
                        urlField.text = "Reader mode"
                    } else {
                        urlField.text = webTitle
                    }
                }
                moveToolbarReturn = false
                
                //update current window store title and url
                if(slideViewValue.readActions == false) {
                    slideViewValue.windowStoreTitle[slideViewValue.windowCurTab] = WKWebviewFactory.sharedInstance.webView.title!
                    slideViewValue.windowStoreUrl[slideViewValue.windowCurTab] = (WKWebviewFactory.sharedInstance.webView.URL?.absoluteString)!
                }
            }
            if(Float(WKWebviewFactory.sharedInstance.webView.estimatedProgress) == 1.0) {
                //set refresh button style
                refreshStopButton.setImage(UIImage(named: "Refresh"), forState: UIControlState.Normal)
                refreshStopButton.addTarget(self, action: #selector(ViewController.refreshPressed), forControlEvents: UIControlEvents.TouchUpInside)
                
                
                //Store value for History feature
                if webAddress != "about:blank" {
                    if (slideViewValue.historyUrl.count == 0) { //while history is empty...
                        slideViewValue.historyTitle.append(webTitle)
                        slideViewValue.historyUrl.append((WKWebviewFactory.sharedInstance.webView.URL?.absoluteString)!)
                    }
                    if (slideViewValue.historyUrl.count > 0) { //while history has entries...
                        //check if this address is familer with the one before, if no, insert entry
                        if webAddress != slideViewValue.historyUrl[slideViewValue.historyUrl.count-1] {
                            slideViewValue.historyTitle.append(webTitle)
                            slideViewValue.historyUrl.append((WKWebviewFactory.sharedInstance.webView.URL?.absoluteString)!)
                        }
                    }
                }
            }
        }
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        if (error.code != NSURLErrorCancelled) {
            //Popup alert window
            hideKeyboard()
            slideViewValue.alertPopup(0, message: error.localizedDescription)
            if (error.code == NSURLErrorTimedOut) {
                loadRequest("about:blank")
            }
        }
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        //disable the original wkactionsheet
        webView.evaluateJavaScript("document.body.style.webkitTouchCallout='none';", completionHandler: nil)
        if(slideViewValue.scrollPositionSwitch == true) {
            WKWebviewFactory.sharedInstance.webView.scrollView.setContentOffset(CGPointMake(0.0, CGFloat(NSNumberFormatter().numberFromString(slideViewValue.scrollPosition[slideViewValue.windowCurTab])!)), animated: true)
            slideViewValue.scrollPositionSwitch = false
        }
        progressView.setProgress(0.0, animated: false)
        
        //update handoff
        if(webAddress != "about:blank") {
            self.activity.webpageURL = WKWebviewFactory.sharedInstance.webView.URL
            self.activity.becomeCurrent()
        }
    }
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        WKWebviewFactory.sharedInstance.webView.scrollView.setContentOffset(CGPointZero, animated: false)
    }
    
    // this handles target=_blank links by opening them in the same view
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            loadRequest((navigationAction.request.URL?.absoluteString)!)
        }
        return nil
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        let url: NSURL = navigationAction.request.URL!
        let urlString: String = url.absoluteString
        if (matchesForRegexInText("\\/\\/itunes\\.apple\\.com\\/", text: urlString) != []) {
            UIApplication.sharedApplication().openURL(url)
            decisionHandler(.Cancel)
            return;
        }
        else {
            if navigationAction.navigationType == .LinkActivated && longPressSwitch == true {
                self.actionMenu(self, urlStr: urlString)
                decisionHandler(.Cancel)
                longPressSwitch = false
                return
            }
            if navigationAction.navigationType == .BackForward {
                //handles the actions when the webview instance is backward or forward
                slideViewValue.readActions = false //disable readbility
                hideKeyboard()
            }
        }
        decisionHandler(.Allow)
    }

    //Rebuild Wkactionsheet
    func actionMenu(sender: UIViewController, urlStr: String) {
        let alertController = UIAlertController(title: "", message: urlStr, preferredStyle: .ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            
        }
        alertController.addAction(cancelAction)
        let openAction = UIAlertAction(title: "Open", style: .Default) { (action) in
            //reset readActions
            slideViewValue.readActions = false
            slideViewValue.readRecover = false
            slideViewValue.readActionsCheck = false
            
            self.loadRequest(urlStr)
        }
        alertController.addAction(openAction)
        let opentabAction = UIAlertAction(title: "Open In New Tab", style: .Default) { (action) in
            //store previous window titles and urls
            slideViewValue.windowStoreTitle.append(urlStr)
            slideViewValue.windowStoreUrl.append(urlStr)
            
            //set current window as the latest window
            slideViewValue.windowCurTab = slideViewValue.windowStoreTitle.count - 1
            
            //update windows count
            self.windowView.setTitle(String(slideViewValue.windowStoreTitle.count), forState: UIControlState.Normal)
            
            //initial y point
            slideViewValue.scrollPosition.append("0.0")
            
            //reset readActions
            slideViewValue.readActions = false
            slideViewValue.readRecover = false
            slideViewValue.readActionsCheck = false
            
            self.loadRequest(urlStr)
        }
        alertController.addAction(opentabAction)
        let copyurlAction = UIAlertAction(title: "Copy Link", style: .Default) { (action) in
            let pb: UIPasteboard = UIPasteboard.generalPasteboard();
            pb.string = urlStr
        }
        alertController.addAction(copyurlAction)
        let shareAction = UIAlertAction(title: "Share Link", style: .Default) { (action) in
            let activityViewController = UIActivityViewController(activityItems: [urlStr as NSString], applicationActivities: nil)
            if let vcpopController = activityViewController.popoverPresentationController {
                vcpopController.sourceView = self.view
                vcpopController.sourceRect = CGRectMake(self.touchPoint.x, self.touchPoint.y, 1.0, 1.0)
            }
            self.presentViewController(activityViewController, animated: true, completion: nil)
        }
        alertController.addAction(shareAction)
        
        /* iPad support */
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(touchPoint.x, touchPoint.y, 1.0, 1.0)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //function to refresh
    func refreshPressed() {
        if(slideViewValue.readActions == false) {
            loadRequest(slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])
        }
        else if(slideViewValue.readActions == true) {
            loadRequest(tempUrl) //load contents by wkwebview
        }
        slideViewValue.scrollPositionSwitch = false
        slideViewValue.readActionsCheck = false
    }
    
    //function to stop page loading
    func stopPressed() {
        if WKWebviewFactory.sharedInstance.webView.loading {
            WKWebviewFactory.sharedInstance.webView.stopLoading()
        }
    }
    
    //function to clear urlfield
    func clearPressed(){
        urlField.text = ""
    }
    
    //function to copy text
    func copyPressed() {
        let pb: UIPasteboard = UIPasteboard.generalPasteboard();
        pb.string = urlField.text
    }
    
    //function to cut text
    func cutPressed() {
        let pb: UIPasteboard = UIPasteboard.generalPasteboard();
        pb.string = urlField.text
        urlField.text = ""
    }
    
    //function to paste text
    func pastePressed() {
        let pb: UIPasteboard = UIPasteboard.generalPasteboard();
        urlField.text = pb.string
    }
    
    //fill webView by 1Password Extension
    func pwPressed(sender: AnyObject) {
        hideKeyboard()
        OnePasswordExtension.sharedExtension().fillItemIntoWebView(WKWebviewFactory.sharedInstance.webView, forViewController: self, sender: sender, showOnlyLogins: false) { (success, error) -> Void in
            if success == false {
                slideViewValue.alertPopup(0, message: "1Password failed to fill into webview.")
            }
        }
    }
    
    //function to load Google search
    func searchPressed() {
        if(slideViewValue.searchEngines == 0) {
            slideViewValue.searchEngines = 1
            //slideViewValue.alertPopup(3, message: "Your search engine was changed to Bing")
            self.view.makeToast("Bing It On!", duration: 0.8, position: CGPoint(x: self.view.frame.size.width/2, y: UIScreen.mainScreen().bounds.height-70))
        } else {
            slideViewValue.searchEngines = 0
            //slideViewValue.alertPopup(3, message: "Your search engine was changed to Google")
            self.view.makeToast("Let's Google it!", duration: 0.8, position: CGPoint(x: self.view.frame.size.width/2, y: UIScreen.mainScreen().bounds.height-70))
        }
    }
    
    //add slash to urlfield
    func addSlash() {
        urlField.text = urlField.text! + "/"
    }
    
    //function to hide keyboard
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }
}

//extend toolbar of textfield keyboard
extension UIViewController: UITextFieldDelegate{
    func addToolBar(textField: UITextField){
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.Black
        toolBar.translucent = true
        toolBar.tintColor = UIColor(red: 236/255, green: 240/255, blue: 241/255, alpha: 1)
        
        //cut button
        let cButton = UIButton(type: UIButtonType.System)
        cButton.setImage(UIImage(named: "Cut"), forState: UIControlState.Normal)
        cButton.addTarget(self, action: #selector(ViewController.cutPressed), forControlEvents: UIControlEvents.TouchUpInside)
        cButton.frame = CGRectMake(0, 0, 30, 30)
        let cutButton = UIBarButtonItem(customView: cButton)
        
        //copy button
        let cpButton = UIButton(type: UIButtonType.System)
        cpButton.setImage(UIImage(named: "Copy"), forState: UIControlState.Normal)
        cpButton.addTarget(self, action: #selector(ViewController.copyPressed), forControlEvents: UIControlEvents.TouchUpInside)
        cpButton.frame = CGRectMake(0, 0, 30, 30)
        let copyButton = UIBarButtonItem(customView: cpButton)
        
        //paste button
        let pButton = UIButton(type: UIButtonType.System)
        pButton.setImage(UIImage(named: "Paste"), forState: UIControlState.Normal)
        pButton.addTarget(self, action: #selector(ViewController.pastePressed), forControlEvents: UIControlEvents.TouchUpInside)
        pButton.frame = CGRectMake(0, 0, 30, 30)
        let pasteButton = UIBarButtonItem(customView: pButton)
        
        //new tab button
        let nButton = UIButton(type: UIButtonType.System)
        nButton.setImage(UIImage(named: "Password"), forState: UIControlState.Normal)
        nButton.addTarget(self, action: #selector(ViewController.pwPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        nButton.frame = CGRectMake(0, 0, 30, 30)
        let plusButton = UIBarButtonItem(customView: nButton)
        
        //refresh button
        let rButton = UIButton(type: UIButtonType.System)
        rButton.setImage(UIImage(named: "Search"), forState: UIControlState.Normal)
        rButton.addTarget(self, action: #selector(ViewController.searchPressed), forControlEvents: UIControlEvents.TouchUpInside)
        rButton.frame = CGRectMake(0, 0, 30, 30)
        let refreshButton = UIBarButtonItem(customView: rButton)
        
        //slash button
        let sButton = UIButton(type: UIButtonType.System)
        sButton.setImage(UIImage(named: "Slash"), forState: UIControlState.Normal)
        sButton.addTarget(self, action: #selector(ViewController.addSlash), forControlEvents: UIControlEvents.TouchUpInside)
        sButton.frame = CGRectMake(0, 0, 30, 30)
        let slashButton = UIBarButtonItem(customView: sButton)
        
        //hide keyboard button
        let hkButton = UIButton(type: UIButtonType.System)
        hkButton.setImage(UIImage(named: "Hide"), forState: UIControlState.Normal)
        hkButton.addTarget(self, action: #selector(ViewController.hideKeyboard), forControlEvents: UIControlEvents.TouchUpInside)
        hkButton.frame = CGRectMake(0, 0, 30, 30)
        let hideButton = UIBarButtonItem(customView: hkButton)
        
        //add some space
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        toolBar.setItems([cutButton, copyButton, pasteButton, spaceButton, hideButton, spaceButton, slashButton, plusButton, refreshButton], animated: false)
        toolBar.userInteractionEnabled = true
        toolBar.sizeToFit()
        
        textField.delegate = self
        textField.inputAccessoryView = toolBar
    }
}
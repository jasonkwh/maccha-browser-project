/*
*  ViewController.swift
*  quaza-browser-project
*
*  This Source Code Form is subject to the terms of the Mozilla Public
*  License, v. 2.0. If a copy of the MPL was not distributed with this
*  file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*  Created by Jason Wong on 28/01/2016.
*  Copyright © 2016 Studios Pâtes, Jason Wong (mail: jasonkwh@gmail.com).
*/

import UIKit
import WebKit
import AudioToolbox

struct slideViewValue {
    static var scrollCellAction: Bool = false
    static var newtabButton: Bool = false
    static var safariButton: Bool = false
    static var cellActions: Bool = false
    static var deleteTab: Bool = false
    static var windowStoreTitle = [String]() //can be change
    static var windowStoreUrl = [String]() //can be change
    static var windowCurTab: Int = 0 //can be change
    static var windowCurColour: UIColor! //can be change
    static var aboutScreen: Bool = false
    static var alertScreen: Bool = false
    static var alertContents: String = ""
    static var scrollPosition = [CGFloat]() //can be change
    static var shortcutItem: Int = 0
    
    //get versions information from Xcode Project Setting
    static func version() -> String {
        let dictionary = NSBundle.mainBundle().infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "\(version).\(build)"
    }
    
    //alert popups (for about and alert message popups)
    static func alertPopup(alertType: Bool, message: String) {
        if(alertType == true) {
            slideViewValue.alertScreen = true
            slideViewValue.alertContents = message
        }
        else {
            slideViewValue.aboutScreen = true
        }
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
}

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate, SWRevealViewControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mask: UIView!
    var webView: WKWebView
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
    var toolbarStyle: Int = 0 //can be change
    var navBar: UINavigationBar = UINavigationBar()
    var scrollDirectionDetermined: Bool = false
    var scrollMakeStatusBarDown: Bool = false
    var homepage: String = "https://www.google.com" //can be change
    
    //remember previous scrolling position~~
    let panPressRecognizer = UIPanGestureRecognizer()
    var scrollPositionRecord: Bool = false //user tap, record scroll position
    var scrollPositionSwitch: Bool = false //switch position scroll when revealViewController is close
    
    //actionsheet
    //var longPressRecognizer = UILongPressGestureRecognizer()
    //var longPressSwitch: Bool = false
    
    //Search Engines
    //0: Google, 1: Baidu
    //International edition, original setting
    var searchEngines:Int = 0
    
    //China edition, original setting
    //var searchEngines:Int = 1
    
    required init?(coder aDecoder: NSCoder) {
        self.webView = WKWebView(frame: CGRectZero)
        super.init(coder: aDecoder)
        
        self.webView.navigationDelegate = self
        self.webView.UIDelegate = self
        self.webView.scrollView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //use Reach() module to check network connections
        Reach().monitorReachabilityChanges()
        
        self.revealViewController().delegate = self
        if self.revealViewController() != nil {
            revealViewController().rightViewRevealWidth = 240
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        mask.backgroundColor = UIColor.blackColor()
        mask.alpha = 0
        
        addToolBar(urlField)
        
        //setup urlfield style
        definesUrlfield()
        
        //display refresh or change to stop while loading...
        displayRefreshOrStop()
        
        //set original homepage at index 0 of store array
        slideViewValue.windowStoreTitle = ["Google"]
        slideViewValue.windowStoreUrl = [homepage]
        slideViewValue.scrollPosition = [(CGFloat(0.0))]
        
        //display current window number on the window button
        displayCurWindowNum(slideViewValue.windowStoreTitle.count)
        
        //set toolbar color and style
        bar.clipsToBounds = true
        toolbarColor(toolbarStyle)
        
        //snapshot webview after loading new screens
        self.webView.snapshotViewAfterScreenUpdates(true)
        
        //hide navigation bar
        self.navigationController?.navigationBarHidden = true
        
        //set new navigation bar
        setNavBarToTheView()
        
        //hook the tap press event
        panPressRecognizer.delegate = self
        panPressRecognizer.addTarget(self, action: "onPanPress:")
        self.webView.scrollView.addGestureRecognizer(panPressRecognizer)
        
        //long press to show the action sheet
        /*longPressRecognizer.delegate = self
        longPressRecognizer.addTarget(self, action: "onLongPress:")
        self.webView.scrollView.addGestureRecognizer(longPressRecognizer)*/
        
        //user agent string
        let ver:String = "Kapiko/4.0 Quaza/" + slideViewValue.version()
        webView.performSelector("_setApplicationNameForUserAgent:", withObject: ver)
        
        //enable Back & Forward gestures
        webView.allowsBackForwardNavigationGestures = true
        
        barView.frame = CGRect(x:0, y: 0, width: view.frame.width, height: 30)
        view.insertSubview(webView, belowSubview: progressView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        let height = NSLayoutConstraint(item: webView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: -44)
        let width = NSLayoutConstraint(item: webView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
        view.addConstraints([height, width])
        
        webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
        
        backButton.enabled = false
        forwardButton.enabled = false
        
        //Determine quick actions...
        if(slideViewValue.shortcutItem == 0) {
            loadRequest(slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])
        }
        else {
            slideViewValue.windowStoreTitle.append("")
            slideViewValue.windowStoreUrl.append("about:blank")
            slideViewValue.scrollPosition.append(CGFloat(0.0))
            slideViewValue.windowCurTab = slideViewValue.windowStoreTitle.count - 1
            windowView.setTitle(String(slideViewValue.windowStoreTitle.count), forState: UIControlState.Normal)
            if(slideViewValue.shortcutItem == 1) {
                webView.loadRequest(NSURLRequest(URL:NSURL(string: "about:blank")!))
            }
            else if(slideViewValue.shortcutItem == 2) {
                //Open URL from clipboard
                let pb: UIPasteboard = UIPasteboard.generalPasteboard()
                loadRequest(pb.string!)
                slideViewValue.windowStoreTitle[slideViewValue.windowCurTab] = webView.title!
                slideViewValue.windowStoreUrl[slideViewValue.windowCurTab] = (webView.URL?.absoluteString)!
            }
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
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
    
    /*func onLongPress(gestureRecognizer:UIGestureRecognizer){
        longPressSwitch = true
    }*/

    //function to hide the statusbar
    func hideStatusbar() {
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
        UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.navBar.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 0)
            }, completion: { finished in
            })
    }
    
    //function to show the statusbar
    func showStatusbar() {
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
        UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.navBar.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 20)
            }, completion: { finished in
            })
    }
    
    //detect the right reveal view is toggle, and do some actions...
    func revealController(revealController: SWRevealViewController!, willMoveToPosition position: FrontViewPosition) {
        if revealController.frontViewPosition == FrontViewPosition.Left
        {
            hideKeyboard()
            hideStatusbar()
            self.webView.userInteractionEnabled = false
            self.bar.userInteractionEnabled = false
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.mask.alpha = 0.6
                }, completion: { finished in
            })
        }
        else
        {
            windowView.setTitle(String(slideViewValue.windowStoreTitle.count), forState: UIControlState.Normal)
            self.webView.userInteractionEnabled = true
            self.bar.userInteractionEnabled = true
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.mask.alpha = 0
                }, completion: { finished in
            })
            if(slideViewValue.safariButton == true) {
                //use safari to open
                safariPressed()
                slideViewValue.safariButton = false
            }
            if(slideViewValue.cellActions == true) {
                //open stored urls
                webView.loadRequest(NSURLRequest(URL: NSURL(string: slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 15))
                scrollPositionSwitch = true
                slideViewValue.cellActions = false
            }
            if(slideViewValue.newtabButton == true) {
                //open new tab
                webView.loadRequest(NSURLRequest(URL:NSURL(string: "about:blank")!))
                slideViewValue.windowStoreTitle.append(webView.title!)
                slideViewValue.windowStoreUrl.append((webView.URL?.absoluteString)!)
                
                //initial y point
                slideViewValue.scrollPosition.append(CGFloat(0.0))
                
                slideViewValue.windowCurTab = slideViewValue.windowStoreTitle.count - 1
                slideViewValue.newtabButton = false
            }
            if(slideViewValue.deleteTab == true) {
                webView.loadRequest(NSURLRequest(URL:NSURL(string: slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])!))
                scrollPositionSwitch = true
                slideViewValue.deleteTab = false
            }
        }
    }
    
    //scroll down to hide status bar, scroll up to show status bar, with animations
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //store current scroll positions to array
        if(scrollPositionRecord == true) {
            slideViewValue.scrollPosition[slideViewValue.windowCurTab] = scrollView.contentOffset.y
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
    
    //set navigation bar style
    func setNavBarToTheView()
    {
        navBar.frame=CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 20)
        navBar.translucent = false
        navBar.clipsToBounds = true
        self.view.addSubview(navBar)
        
        //auto-hide at the beginning...
        hideStatusbar()
    }
    
    override func canResignFirstResponder() -> Bool {
        return true
    }
    
    //shake to change toolbar color, phone will vibrate for confirmation
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == .MotionShake {
            if(toolbarStyle < 1) {
                toolbarStyle++
                print(toolbarStyle)
            }
            else {
                toolbarStyle = 0
            }
            toolbarColor(toolbarStyle)
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
            navBar.barTintColor = UIColor(netHex:0x70BF41)
            slideViewValue.windowCurColour = UIColor(netHex:0x70BF41)
        case 1:
            //Blue
            progressView.tintColor = UIColor(netHex:0x0153A4)
            urlField.backgroundColor = UIColor(netHex:0x0153A4)
            bar.barTintColor = UIColor(netHex:0x499AE7)
            navBar.barTintColor = UIColor(netHex:0x499AE7)
            slideViewValue.windowCurColour = UIColor(netHex:0x499AE7)
        default:
            break
        }
    }
    
    //function which defines the clear button of the urlfield and some characteristics of urlfield
    func definesUrlfield() {
        //changes scales exclusively for iPhone 6 Plus or iPhone 6s Plus
        if((UIDevice.currentDevice().modelName == "iPhone 6 Plus") || (UIDevice.currentDevice().modelName == "iPhone 6s Plus") || (UIDevice.currentDevice().modelName == "Simulator")) {
            urlField.frame.size.width = 208
        }
        urlField.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        urlField.clipsToBounds = true
        let crButton = UIButton(type: UIButtonType.System)
        crButton.setImage(UIImage(named: "Clear"), forState: UIControlState.Normal)
        crButton.addTarget(self, action: "clearPressed", forControlEvents: UIControlEvents.TouchUpInside)
        crButton.imageEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 5)
        crButton.frame = CGRectMake(0, 0, 15, 15)
        urlField.rightViewMode = .WhileEditing
        urlField.rightView = crButton
    }
    
    //function to display current window number in the window button
    func displayCurWindowNum(currentNum: Int) {
        windowView.setBackgroundImage(UIImage(named: "Window"), forState: UIControlState.Normal)
        windowView.setTitle(String(currentNum), forState: UIControlState.Normal)
        windowView.addTarget(revealViewController(), action: "rightRevealToggle:", forControlEvents: UIControlEvents.TouchUpInside)
        windowView.frame = CGRectMake(0, 0, 30, 30)
    }
    
    //function to display refresh or change to stop while loading...
    func displayRefreshOrStop() {
        refreshStopButton.setImage(UIImage(named: "Refresh"), forState: UIControlState.Normal)
        refreshStopButton.addTarget(self, action: "refreshPressed", forControlEvents: UIControlEvents.TouchUpInside)
        refreshStopButton.imageEdgeInsets = UIEdgeInsetsMake(0, -13, 0, -15)
        refreshStopButton.frame = CGRectMake(0, 0, 30, 30)
    }
    
    //keyboards related
    //show/hide keyboard reactions
    func textFieldDidBeginEditing(textField: UITextField) -> Bool {
        if textField == urlField {
            //move toolbar as the keyboard moves
            moveToolbar = true;
            
            //display urls in urlfield
            if(moveToolbarShown == false) {
                urlField.textAlignment = .Left
                urlField.text = webAddress
                urlField.selectAll(self)
            }
            return true //urlField
        }
        else {
            return false
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //hide navigation bar
        self.navigationController?.navigationBarHidden = true
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //hide navigation bar
        self.navigationController?.navigationBarHidden = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    //auto show toolbar while editing
    func keyboardWillShow(sender: NSNotification) {
        if(moveToolbar == true) {
            moveToolbarShown = true
            if let userInfo = sender.userInfo {
                if let keyboardHeight = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size.height {
                    self.view.frame.origin.y = -keyboardHeight
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
                urlField.text = webTitle
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
        
        return false
    }
    
    //function to load webview request
    func loadRequest(inputUrlAddress: String) {
        
        if (checkConnectionStatus() == true) {
            //shorten the url by replacing http and https to null
            let shorten_url = inputUrlAddress.stringByReplacingOccurrencesOfString("https://", withString: "").stringByReplacingOccurrencesOfString("http://", withString: "").stringByReplacingOccurrencesOfString(" ", withString: "+")
            
            //check if it is URL, else use search engine
            var contents: String = ""
            let matches = matchesForRegexInText("(?i)(?:(?:https?):\\/\\/)?(?:\\S+(?::\\S*)?@)?(?:(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))|(?:(?:[a-z\\u00a1-\\uffff0-9]+-?)*[a-z\\u00a1-\\uffff0-9]+)(?:\\.(?:[a-z\\u00a1-\\uffff0-9]+-?)*[a-z\\u00a1-\\uffff0-9]+)*(?:\\.(?:[a-z\\u00a1-\\uffff]{2,})))(?::\\d{2,5})?(?:\\/[^\\s]*)?", text: ("http://" + shorten_url))
            if(matches == []) {
                if(searchEngines == 0) {
                    contents = "http://www.google.com/search?q=" + shorten_url.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
                }
                else if(searchEngines == 1) {
                    contents = "http://www.baidu.com/s?wd=" + shorten_url.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
                }
            }
            else {
                contents = "http://" + shorten_url
            }
            
            //load contents by wkwebview
            webView.loadRequest(NSURLRequest(URL: NSURL(string: contents)!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 15))
        }
        else {
            //Popup alert window
            hideKeyboard()
            slideViewValue.alertPopup(true, message: "The Internet connection appears to be offline.")
            
            //insert a blank page if there's nothing store in the arrays
            if(slideViewValue.windowStoreTitle.count == 0) {
                slideViewValue.windowStoreTitle.append("")
                slideViewValue.windowStoreUrl.append("about:blank")
                
                //initial y point
                slideViewValue.scrollPosition.append(CGFloat(0.0))
            }
        }
    }
    
    //function to check current network status, powered by Reach() module
    func checkConnectionStatus() -> Bool {
        switch Reach().connectionStatus() {
        case .Unknown, .Offline:
            return false
        case .Online(.WWAN):
            return true
        case .Online(.WiFi):
            return true
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
        webView.goBack()
        hideKeyboard()
    }
    
    @IBAction func forward(sender: UIBarButtonItem) {
        webView.goForward()
        hideKeyboard()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<()>) {
        if (keyPath == "loading") {
            backButton.enabled = webView.canGoBack
            forwardButton.enabled = webView.canGoForward
        }
        if (keyPath == "estimatedProgress") {
            progressView.hidden = webView.estimatedProgress == 1
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
            
            if(Float(webView.estimatedProgress) > 0.0) {
                //set refreshStopButton to stop state
                refreshStopButton.setImage(UIImage(named: "Stop"), forState: UIControlState.Normal)
                refreshStopButton.addTarget(self, action: "stopPressed", forControlEvents: UIControlEvents.TouchUpInside)
            }
            if(Float(webView.estimatedProgress) > 0.1) {
                //shorten url by replacing http:// and https:// to null
                let shorten_url = webView.URL?.absoluteString.stringByReplacingOccurrencesOfString("https://", withString: "").stringByReplacingOccurrencesOfString("http://", withString: "")

                //change urlField when the page starts loading
                //display website title in the url field
                webTitle = webView.title! //store title into webTitle for efficient use
                webAddress = shorten_url! //store address into webAddress for efficient use
                if(moveToolbar == false) {
                    urlField.textAlignment = .Center
                    urlField.text = webTitle
                }
                moveToolbarReturn = false
                
                //update current window store title and url
                slideViewValue.windowStoreTitle[slideViewValue.windowCurTab] = webView.title!
                slideViewValue.windowStoreUrl[slideViewValue.windowCurTab] = (webView.URL?.absoluteString)!
                
                //display current window numbers
                windowView.setTitle(String(slideViewValue.windowStoreTitle.count), forState: UIControlState.Normal)
            }
            if(Float(webView.estimatedProgress) == 1.0) {
                refreshStopButton.setImage(UIImage(named: "Refresh"), forState: UIControlState.Normal)
                refreshStopButton.addTarget(self, action: "refreshPressed", forControlEvents: UIControlEvents.TouchUpInside)
            }
        }
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        if (error.code != NSURLErrorCancelled) {
            //Popup alert window
            hideKeyboard()
            slideViewValue.alertPopup(true, message: error.localizedDescription)
        }
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        //disable the original wkactionsheet
        //webView.evaluateJavaScript("document.body.style.webkitTouchCallout='none';", completionHandler: nil)
        if(scrollPositionSwitch == true) {
            self.webView.scrollView.setContentOffset(CGPointMake(0.0, slideViewValue.scrollPosition[slideViewValue.windowCurTab]), animated: true)
            scrollPositionSwitch = false
        }
        progressView.setProgress(0.0, animated: false)
    }
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        self.webView.scrollView.setContentOffset(CGPointZero, animated: false)
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
            /*if navigationAction.navigationType == .LinkActivated && longPressSwitch == true {
                decisionHandler(.Cancel)
                let ac = actionMenu(self, urlStr: urlString)
                self.presentViewController(ac, animated: true) {}
                longPressSwitch = false
                return
            }*/
        }
        decisionHandler(.Allow)
    }

    //Rebuild Wkactionsheet
    /*func actionMenu(sender: UIViewController, urlStr: String) -> UIAlertController {
        let alertController = UIAlertController(title: "", message: urlStr, preferredStyle: .ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            
        }
        alertController.addAction(cancelAction)
        let openAction = UIAlertAction(title: "Open", style: .Default) { (action) in
            self.loadRequest(urlStr)
        }
        alertController.addAction(openAction)
        let opentabAction = UIAlertAction(title: "Open In New Tab", style: .Default) { (action) in
            //reset scrollCellAction
            slideViewValue.scrollCellAction = false
            
            //store previous window titles and urls
            slideViewValue.windowStoreTitle.append(urlStr)
            slideViewValue.windowStoreUrl.append(urlStr)
            
            //set current window as the latest window
            slideViewValue.windowCurTab = slideViewValue.windowStoreTitle.count - 1
            
            //update windows count
            slideViewValue.windowStoreSums = slideViewValue.windowStoreTitle.count
            self.windowView.setTitle(String(slideViewValue.windowStoreSums), forState: UIControlState.Normal)
            
            //initial y point
            slideViewValue.scrollPosition.append(CGFloat(0.0))
            
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
            self.presentViewController(activityViewController, animated: true, completion: {})
        }
        alertController.addAction(shareAction)
        
        return alertController
    }*/
    
    //function to refresh
    func refreshPressed() {
        if (webView.loading == false) {
            webView.reload()
        }
    }
    
    //function to stop page loading
    func stopPressed() {
        if webView.loading {
            webView.stopLoading()
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
    
    //function to new window
    func newWindow() {
        //reset scrollCellAction
        slideViewValue.scrollCellAction = false
        
        //store previous window titles and urls
        slideViewValue.windowStoreTitle.append(webView.title!)
        slideViewValue.windowStoreUrl.append((webView.URL?.absoluteString)!)
        
        //set current window as the latest window
        slideViewValue.windowCurTab = slideViewValue.windowStoreTitle.count - 1
        
        //initial y point
        slideViewValue.scrollPosition.append(CGFloat(0.0))
        
        //open urls
        moveToolbarReturn = true
        urlField.resignFirstResponder()
        
        loadRequest(urlField.text!)
    }
    
    //function to load Google search
    func homePressed() {
        loadRequest(homepage)
        hideKeyboard()
    }
    
    //add slash to urlfield
    func addSlash() {
        urlField.text = urlField.text! + "/"
    }
    
    //function to hide keyboard
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    //function which opens safari to load this url
    func safariPressed() {
        UIApplication.sharedApplication().openURL(NSURL(string: slideViewValue.windowStoreUrl[slideViewValue.windowCurTab])!)
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
        cButton.addTarget(self, action: "cutPressed", forControlEvents: UIControlEvents.TouchUpInside)
        cButton.frame = CGRectMake(0, 0, 30, 30)
        let cutButton = UIBarButtonItem(customView: cButton)
        
        //copy button
        let cpButton = UIButton(type: UIButtonType.System)
        cpButton.setImage(UIImage(named: "Copy"), forState: UIControlState.Normal)
        cpButton.addTarget(self, action: "copyPressed", forControlEvents: UIControlEvents.TouchUpInside)
        cpButton.frame = CGRectMake(0, 0, 30, 30)
        let copyButton = UIBarButtonItem(customView: cpButton)
        
        //paste button
        let pButton = UIButton(type: UIButtonType.System)
        pButton.setImage(UIImage(named: "Paste"), forState: UIControlState.Normal)
        pButton.addTarget(self, action: "pastePressed", forControlEvents: UIControlEvents.TouchUpInside)
        pButton.frame = CGRectMake(0, 0, 30, 30)
        let pasteButton = UIBarButtonItem(customView: pButton)
        
        //new tab button
        let nButton = UIButton(type: UIButtonType.System)
        nButton.setImage(UIImage(named: "Newtab"), forState: UIControlState.Normal)
        nButton.addTarget(self, action: "newWindow", forControlEvents: UIControlEvents.TouchUpInside)
        nButton.frame = CGRectMake(0, 0, 30, 30)
        let plusButton = UIBarButtonItem(customView: nButton)
        
        //refresh button
        let rButton = UIButton(type: UIButtonType.System)
        rButton.setImage(UIImage(named: "Google"), forState: UIControlState.Normal)
        rButton.addTarget(self, action: "homePressed", forControlEvents: UIControlEvents.TouchUpInside)
        rButton.frame = CGRectMake(0, 0, 30, 30)
        let refreshButton = UIBarButtonItem(customView: rButton)
        
        //slash button
        let sButton = UIButton(type: UIButtonType.System)
        sButton.setImage(UIImage(named: "Slash"), forState: UIControlState.Normal)
        sButton.addTarget(self, action: "addSlash", forControlEvents: UIControlEvents.TouchUpInside)
        sButton.frame = CGRectMake(0, 0, 30, 30)
        let slashButton = UIBarButtonItem(customView: sButton)
        
        //hide keyboard button
        let hkButton = UIButton(type: UIButtonType.System)
        hkButton.setImage(UIImage(named: "Hide"), forState: UIControlState.Normal)
        hkButton.addTarget(self, action: "hideKeyboard", forControlEvents: UIControlEvents.TouchUpInside)
        hkButton.frame = CGRectMake(0, 0, 30, 30)
        let hideButton = UIBarButtonItem(customView: hkButton)
        
        //add some space
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        toolBar.setItems([cutButton, copyButton, pasteButton, spaceButton, hideButton, spaceButton, slashButton, refreshButton, plusButton], animated: false)
        toolBar.userInteractionEnabled = true
        toolBar.sizeToFit()
        
        textField.delegate = self
        textField.inputAccessoryView = toolBar
    }
}

//Get user device
public extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 where value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
}

//Hex value color, call by UIColor(netHex:0xF39C12) for orange color #F39C12
public extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}
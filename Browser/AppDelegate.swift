/*
*  AppDelegate.swift
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
import RealmSwift

let realm_maccha = try! Realm()

@available(iOS 9.0, *)
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var shortcutItem: UIApplicationShortcutItem?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool{
        var performShortcutDelegate = true
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            self.shortcutItem = shortcutItem
            performShortcutDelegate = false
        }
        
        //set url cache setting
        let URLCache = NSURLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024, diskPath: nil)
        NSURLCache.setSharedURLCache(URLCache)
        
        return performShortcutDelegate
    }
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        //handoff between iOS apps
        
        //reset readActions
        slideViewValue.readActions = false
        slideViewValue.readRecover = false
        slideViewValue.readActionsCheck = false
        slideViewValue.scrollPositionSwitch = false
        if(slideViewValue.windowStoreUrl[slideViewValue.windowCurTab] != "about:blank") {
            slideViewValue.windowCurTab = slideViewValue.windowCurTab + 1
            slideViewValue.windowStoreTitle.insert("", atIndex: slideViewValue.windowCurTab)
            slideViewValue.windowStoreUrl.insert("about:blank", atIndex: slideViewValue.windowCurTab)
            slideViewValue.scrollPosition.insert("0.0", atIndex: slideViewValue.windowCurTab)
        }
        WKWebviewFactory.sharedInstance.webView.loadRequest(NSURLRequest(URL: userActivity.webpageURL!, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 15))
        return true
    }
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }
    
    func handleShortcut(shortcutItem: UIApplicationShortcutItem) -> Bool {
        var succeeded = false
        if(shortcutItem.type == "com.studiospates.maccha.openclipboard") {
            slideViewValue.shortcutItem = 2
            succeeded = true
        }
        else if(shortcutItem.type == "com.studiospates.maccha.opennewtab") {
            slideViewValue.shortcutItem = 1
            succeeded = true
        }
        return succeeded
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        guard let shortcut = shortcutItem else { return }
        handleShortcut(shortcut)
        self.shortcutItem = nil
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        try! realm_maccha.write {
            //save data to Realm database
            let gdata = GlobalData()
            gdata.current_tab = slideViewValue.windowCurTab
            gdata.search = slideViewValue.searchEngines
            gdata.new_user = slideViewValue.newUser
            realm_maccha.add(gdata)
            let htdata = HistoryData()
            htdata.history_url = slideViewValue.historyUrl
            htdata.history_title = slideViewValue.historyTitle
            htdata.history_date = slideViewValue.historyDate
            let wdata = WkData()
            wdata.wk_url = slideViewValue.windowStoreUrl
            wdata.wk_title = slideViewValue.windowStoreTitle
            wdata.wk_scrollPosition = slideViewValue.scrollPosition
            let bkdata = BookmarkData()
            bkdata.like_title = slideViewValue.likesTitle
            bkdata.like_url = slideViewValue.likesUrl
            realm_maccha.add(wdata)
            realm_maccha.add(gdata)
            realm_maccha.add(htdata)
            realm_maccha.add(bkdata)
        }
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

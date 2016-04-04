/*
 *  Extensions.swift
 *  Maccha Browser
 *
 *  This Source Code Form is subject to the terms of the Mozilla Public
 *  License, v. 2.0. If a copy of the MPL was not distributed with this
 *  file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 *  Created by Jason Wong on 24/03/2016.
 *  Copyright © 2016 Studios Pâtes, Jason Wong (mail: jasonkwh@gmail.com).
 */

struct slideViewValue {
    static var scrollCellAction: Bool = false //false to scroll to latest tab, else do not
    static var newtabButton: Bool = false
    static var safariButton: Bool = false
    static var cellActions: Bool = false
    static var readActions: Bool = false
    static var readRecover: Bool = false
    static var windowStoreTitle = [String]() //save
    static var windowStoreUrl = [String]() //save
    static var windowCurTab: Int = 0 //save
    static var windowCurColour: UIColor!
    static var aboutScreen: Bool = false
    static var alertScreen: Bool = false
    static var doneScreen: Bool = false
    static var searchScreen: Bool = false
    static var alertContents: String = ""
    static var scrollPosition = [String]() //save
    static var shortcutItem: Int = 0
    static var historyTitle = [String]() //save, for history
    static var historyUrl = [String]() //save, for history
    static var htButtonSwitch: Bool = false
    static var htButtonIndex: Int = 0
    static var scrollPositionSwitch: Bool = false //true is scroll back to user view, false is not
    static var newUser: Int = 0 //save
    static var readActionsCheck: Bool = false
    
    //Search Engines
    //0: Google, 1: Bing
    static var searchEngines:Int = 0 //save
    
    //get versions information from Xcode Project Setting
    static func version() -> String {
        let dictionary = NSBundle.mainBundle().infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "\(version).\(build)"
    }
    
    //alert popups (for about and alert message popups)
    static func alertPopup(alertType: Int, message: String) {
        if(alertType == 0) {
            slideViewValue.alertScreen = true
            slideViewValue.alertContents = message
        }
        else if(alertType == 1) {
            slideViewValue.aboutScreen = true
        }
        else if(alertType == 2) {
            slideViewValue.doneScreen = true
            slideViewValue.alertContents = message
        }
        /*else if(alertType == 3) {
         slideViewValue.searchScreen = true
         slideViewValue.alertContents = message
         }*/
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
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9"
        case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7"
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
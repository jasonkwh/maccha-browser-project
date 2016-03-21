/*
*  WkData.swift
*  Maccha Browser
*
*  This Source Code Form is subject to the terms of the Mozilla Public
*  License, v. 2.0. If a copy of the MPL was not distributed with this
*  file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*  Created by Jason Wong on 15/03/2016.
*  Copyright © 2016 Studios Pâtes, Jason Wong (mail: jasonkwh@gmail.com).
*/

import Foundation
import RealmSwift

class WkData: Object {
    
    //store url
    var wk_url: [String] {
        get {
            return _backingWkUrl.map {
                $0.stringValue
            }
        }
        set {
            _backingWkUrl.removeAll()
            _backingWkUrl.appendContentsOf(newValue.map({WkString(value: [$0]) }))
        }
    }
    let _backingWkUrl = List<WkString>()
    
    //store title
    var wk_title: [String] {
        get {
            return _backingWkTitle.map {
                $0.stringValue
            }
        }
        set {
            _backingWkTitle.removeAll()
            _backingWkTitle.appendContentsOf(newValue.map({WkString(value: [$0]) }))
        }
    }
    let _backingWkTitle = List<WkString>()
    
    //store scroll position
    var wk_scrollPosition: [String] {
        get {
            return _backingWkPosition.map {
                $0.stringValue
            }
        }
        set {
            _backingWkPosition.removeAll()
            _backingWkPosition.appendContentsOf(newValue.map({WkString(value: [$0]) }))
        }
    }
    let _backingWkPosition = List<WkString>()
    
// Specify properties to ignore (Realm won't persist these)
    
    override static func ignoredProperties() -> [String] {
        return ["wk_url", "wk_title", "wk_scrollPosition"]
    }
}

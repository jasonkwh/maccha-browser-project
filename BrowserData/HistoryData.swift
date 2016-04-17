/*
*  HistoryData.swift
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

class HistoryData: Object {
    
    //store browser history url
    var history_url: [String] {
        get {
            return _backingHtUrl.map {
                $0.stringValue
            }
        }
        set {
            _backingHtUrl.removeAll()
            _backingHtUrl.appendContentsOf(newValue.map({WkString(value: [$0]) }))
        }
    }
    let _backingHtUrl = List<WkString>()
    
    //store browser history title
    var history_title: [String] {
        get {
            return _backingHtTitle.map {
                $0.stringValue
            }
        }
        set {
            _backingHtTitle.removeAll()
            _backingHtTitle.appendContentsOf(newValue.map({WkString(value: [$0]) }))
        }
    }
    let _backingHtTitle = List<WkString>()
    
    //store browser history date
    var history_date: [String] {
        get {
            return _backingHtDate.map {
                $0.stringValue
            }
        }
        set {
            _backingHtDate.removeAll()
            _backingHtDate.appendContentsOf(newValue.map({WkString(value: [$0]) }))
        }
    }
    let _backingHtDate = List<WkString>()
    
// Specify properties to ignore (Realm won't persist these)
    
    override static func ignoredProperties() -> [String] {
        return ["history_url", "history_title", "history_date"]
    }
}

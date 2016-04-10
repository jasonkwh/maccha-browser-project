/*
 *  BookmarkData.swift
 *  Maccha Browser
 *
 *  This Source Code Form is subject to the terms of the Mozilla Public
 *  License, v. 2.0. If a copy of the MPL was not distributed with this
 *  file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 *  Created by Jason Wong on 10/04/2016.
 *  Copyright © 2016 Studios Pâtes, Jason Wong (mail: jasonkwh@gmail.com).
 */

import Foundation
import RealmSwift

class BookmarkData: Object {
    
    //store browser history url
    var like_url: [String] {
        get {
            return _backingBkUrl.map {
                $0.stringValue
            }
        }
        set {
            _backingBkUrl.removeAll()
            _backingBkUrl.appendContentsOf(newValue.map({WkString(value: [$0]) }))
        }
    }
    let _backingBkUrl = List<WkString>()
    
    //store browser history title
    var like_title: [String] {
        get {
            return _backingBkTitle.map {
                $0.stringValue
            }
        }
        set {
            _backingBkTitle.removeAll()
            _backingBkTitle.appendContentsOf(newValue.map({WkString(value: [$0]) }))
        }
    }
    let _backingBkTitle = List<WkString>()
    
// Specify properties to ignore (Realm won't persist these)
    
    override static func ignoredProperties() -> [String] {
        return ["like_url", "like_title"]
    }
}

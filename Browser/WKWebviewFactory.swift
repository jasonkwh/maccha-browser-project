/*
*  WKWebviewFactory.swift
*  Maccha Browser
*
*  This Source Code Form is subject to the terms of the Mozilla Public
*  License, v. 2.0. If a copy of the MPL was not distributed with this
*  file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*  Created by Jason Wong on 13/03/2016.
*  Copyright © 2016 Studios Pâtes, Jason Wong (mail: jasonkwh@gmail.com).
*/

import WebKit

class WKWebviewFactory {
    var webView = WKWebView()
    
    //share wkwebview instance to all view controllers
    static var sharedInstance = WKWebviewFactory()
}
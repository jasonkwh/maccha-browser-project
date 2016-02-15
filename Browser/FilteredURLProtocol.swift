/*
*  FilteredURLProtocol.swift
*  quaza-browser-project
*
*  This Source Code Form is subject to the terms of the Mozilla Public
*  License, v. 2.0. If a copy of the MPL was not distributed with this
*  file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
*  Created by Jason Wong on 3/02/2016.
*  Copyright © 2016 Studios Pâtes, Jason Wong (mail: jasonkwh@gmail.com).
*/

import UIKit

class FilteredURLProtocol: NSURLProtocol {
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        let host = request.URL!.host
        
        //detect ads
        if host?.rangeOfString("ads") != nil {
            return true;
        }
        return false
    }
    
    override class func canonicalRequestForRequest (request: NSURLRequest) -> NSURLRequest {
        return request;
    }
    
    override func startLoading() {
        let response = NSURLResponse(URL: self.request.URL!,
            MIMEType: nil,
            expectedContentLength: 0,
            textEncodingName: nil)
        self.client?.URLProtocol(self,
            didReceiveResponse: response,
            cacheStoragePolicy: NSURLCacheStoragePolicy.NotAllowed)
        self.client?.URLProtocol(self, didLoadData: NSData(bytes: nil, length: 0))
        self.client?.URLProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}
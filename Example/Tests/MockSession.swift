//
//  MockSession.swift
//  Feeder
//
//  Created by Tatsuya Tobioka on 11/23/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

class MockSession: URLSession {
    
    let data: Data
    
    init(data: Data) {
        self.data = data
        super.init()
    }
    
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return MockTask(data: data, completionHandler: completionHandler)
    }
}

class MockTask: URLSessionDataTask {

    let data: Data
    let completionHandler: (Data?, URLResponse?, NSError?) -> Void
    
    init(data: Data, completionHandler: @escaping (Data?, URLResponse?, NSError?) -> Void) {
        self.data = data
        self.completionHandler = completionHandler
        super.init()
    }
    
    override func resume() {
        completionHandler(data, nil, nil)
    }
}

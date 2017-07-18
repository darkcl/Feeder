//
//  Feeder.swift
//  Pods
//
//  Created by Tatsuya Tobioka on 11/19/15.
//
//

import Foundation

open class Feeder {
    open static let shared = Feeder()
    
    public typealias FinderCallback = (Page, Error?) -> Void
    public typealias ParserCallback = ([Entry], Error?) -> Void
    
    open var session = URLSession.shared
    
    open func find(_ urlString: String, callback: @escaping FinderCallback) {
        let _ = Finder(urlString: urlString, callback: callback)
    }

    open func parse(_ urlString: String, callback: @escaping ParserCallback) {
        let _ = Parser(urlString: urlString, callback: callback)
    }

    open func parse(_ feed: Feed, callback: @escaping ParserCallback) {
        parse(feed.href, callback: callback)
    }
}

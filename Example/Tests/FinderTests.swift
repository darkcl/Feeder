//
//  FinderTests.swift
//  Feeder
//
//  Created by Tatsuya Tobioka on 11/23/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import XCTest
import Feeder

class FinderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testFind() {
        let filenames = ["test.html", "test.xhtml"]
        for filename in filenames {
            find(filename) { page, error in
                XCTAssertEqual(page.title, "test")
                XCTAssertEqual(page.href, "http://example.com/\(filename)")
                
                XCTAssertEqual(page.feeds.count, 3)
                
                XCTAssertEqual(page.feeds[0].format, Format.atom)
                XCTAssertEqual(page.feeds[0].href, "http://example.com/posts.atom")
                XCTAssertEqual(page.feeds[0].title, "Atom")
                
                XCTAssertEqual(page.feeds[1].format, Format.rss)
                XCTAssertEqual(page.feeds[1].href, "http://example.com/posts.rss")
                XCTAssertEqual(page.feeds[1].title, "RSS")
                
                XCTAssertEqual(page.feeds[2].format, Format.rdf)
                XCTAssertEqual(page.feeds[2].href, "http://example.com/posts.rdf")
                XCTAssertEqual(page.feeds[2].title, "RDF")
            }
        }
    }
    
    func testFindWithAtom() {
        let filename = "test.atom"
        find(filename) { page, error in
            XCTAssertEqual(page.title, "Example Feed")
            XCTAssertEqual(page.href, "http://example.org/")

            XCTAssertEqual(page.feeds.count, 1)
            
            XCTAssertEqual(page.feeds[0].format, Format.atom)
            XCTAssertTrue(page.feeds[0].href.hasSuffix(filename))
            XCTAssertEqual(page.feeds[0].title, "")
        }
    }
    
    func testFindWithRSS() {
        let filename = "test.rss"
        find(filename) { page, error in
            XCTAssertEqual(page.title, "Liftoff News")
            XCTAssertEqual(page.href, "http://liftoff.msfc.nasa.gov/")

            XCTAssertEqual(page.feeds.count, 1)
            
            XCTAssertEqual(page.feeds[0].format, Format.rss)
            XCTAssertTrue(page.feeds[0].href.hasSuffix(filename))
            XCTAssertEqual(page.feeds[0].title, "")
        }
    }

    func testFindWithRDF() {
        let filename = "test.rdf"
        find(filename) { page, error in
            XCTAssertEqual(page.title, "XML.com")
            XCTAssertEqual(page.href, "http://xml.com/pub")

            XCTAssertEqual(page.feeds.count, 1)
            
            XCTAssertEqual(page.feeds[0].format, Format.rdf)
            XCTAssertTrue(page.feeds[0].href.hasSuffix(filename))
            XCTAssertEqual(page.feeds[0].title, "")
        }
    }
    
    fileprivate func find(_ filename: String, callback: @escaping Feeder.FinderCallback) {
        let expectation = self.expectation(description: "")
        guard let path = Bundle.main.path(forResource: filename, ofType: nil) else { return XCTFail() }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return XCTFail() }
        let urlString = "http://example.com/\(filename)"
        
        Feeder.shared.session = MockSession(data: data)
        
        Feeder.shared.find(urlString) { page, error in
            callback(page, error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}

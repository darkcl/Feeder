//
//  Finder.swift
//  Pods
//
//  Created by Tatsuya Tobioka on 11/19/15.
//
//

import Foundation

class Finder: NSObject, XMLParserDelegate {
    
    let url: URL
    let callback: Feeder.FinderCallback
    
    var parser: XMLParser!
    var data: Data!
    
    var format: Format?
    var elementName: String?
    var page = Page()
    
    init(urlString: String, callback: @escaping Feeder.FinderCallback) {
        url = URL(string: urlString)!
        self.callback = callback
        super.init()
        
        let task = Feeder.shared.session.dataTask(with: url, completionHandler: { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    self.parser = XMLParser(data: data)
                    self.data = data

                    self.parser.delegate = self
                    self.parser.parse()
                } else {
                    self.callback(self.page, error as NSError?)
                }
            }
        })
        task.resume()
    }
    
    // MARK: Utility
    
    func absoluteURLString(_ href: String) -> String {
        let urlString: String
        
        let baseURL = URL(string: "\(url.scheme!)://\(url.host!)/")!
        
        if href.hasPrefix("//") {
            urlString = "\(baseURL.scheme!):\(href)"
        } else if href.hasPrefix("/") || href.hasPrefix(".") {
            urlString = URL(string: href, relativeTo: baseURL)!.absoluteString
        } else {
            urlString = href
        }

        return urlString
    }
    
    // MARK: NSXMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        self.elementName = elementName

        switch elementName {
        case "link":
            switch format {
            case nil:
                guard let rel = attributeDict["rel"], rel.hasPrefix("alternat") else { return }
                
                guard let type = attributeDict["type"] else { return }
                guard let format = Format(contentType: type) else { return }
                
                guard let href = attributeDict["href"] else { return }
                
                let urlString = absoluteURLString(href)
                
                let title = attributeDict["title"] ?? ""
                
                let feed = Feed(format: format, href: urlString, title: title)
                page.feeds.append(feed)
                
                page.href = url.absoluteString
            case .atom?:
                if page.href.isEmpty {
                    guard let href = attributeDict["href"] else { return }
                    page.href = href
                }
            default:
                break
            }
        case "feed":
            format = .atom
        case "rss":
            format = .rss
        case "rdf:RDF":
            format = .rdf
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch (format, elementName) {
        case (nil, "title"?):
            page.title += string
        case (.some(let format), "title"?):
            if page.title.isEmpty {
                page.title = string                
            }
            if page.feeds.isEmpty {
                let feed = Feed(format: format, href: url.absoluteString, title: "")
                page.feeds = [feed]
            }
        case (.rss?, "link"?), (.rdf?, "link"?):
            if page.href.isEmpty {
                page.href = string
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        self.elementName = ""
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        callback(page, nil)
    }
    
    // TODO use var for feed
    // TODO parse remainings
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        //print(parseError.localizedDescription)
        if page.feeds.isEmpty {
            page.href = url.absoluteString
            
            guard let html = String(data: data, encoding: String.Encoding.utf8) else { return callback(page, nil) }

            if page.title.isEmpty {
                guard let titleRegexp = try? NSRegularExpression(pattern: "<title>(.+?)</title>", options: .caseInsensitive) else { return }
                if let result = titleRegexp.firstMatch(in: html, options: [], range: NSMakeRange(0, html.characters.count)) {
                    page.title = (html as NSString).substring(with: result.rangeAt(1))
                }                
            }
            
            guard let linkRegexp = try? NSRegularExpression(pattern: "<link[^>]*>", options: .caseInsensitive) else { return callback(page, nil) }
            linkRegexp.enumerateMatches(in: html, options: [], range: NSMakeRange(0, html.characters.count)) { result, _, _ in
                guard let result = result else { return }
                let link = (html as NSString).substring(with: result.range)
                if let _ = link.range(of: "alternat") {
                    var title = ""
                    guard let titleRegexp = try? NSRegularExpression(pattern: "title=\"(.+?)\"", options: .caseInsensitive) else { return }
                    if let result = titleRegexp.firstMatch(in: link, options: [], range: NSMakeRange(0, link.characters.count)) {
                        title = (link as NSString).substring(with: result.rangeAt(1))
                    }
                    
                    var href = ""
                    guard let hrefRegexp = try? NSRegularExpression(pattern: "href=\"(.+?)\"", options: .caseInsensitive) else { return }
                    if let result = hrefRegexp.firstMatch(in: link, options: [], range: NSMakeRange(0, link.characters.count)) {
                        href = (link as NSString).substring(with: result.rangeAt(1))
                    }

                    guard let typeRegexp = try? NSRegularExpression(pattern: "type=\"(.+?)\"", options: .caseInsensitive) else { return }
                    if let result = typeRegexp.firstMatch(in: link, options: [], range: NSMakeRange(0, link.characters.count)) {
                        let type = (link as NSString).substring(with: result.rangeAt(1))
                        if let format = Format(contentType: type) {
                            let feed = Feed(format: format, href: self.absoluteURLString(href), title: title)
                            self.page.feeds.append(feed)
                        }
                    }
                }
            }
            
            callback(page, nil)
        } else {
            callback(page, nil)            
        }
    }
}

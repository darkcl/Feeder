//
//  Parser.swift
//  Pods
//
//  Created by Tatsuya Tobioka on 11/19/15.
//
//

import Foundation

class Parser: NSObject, XMLParserDelegate {

    let url: URL
    let callback: Feeder.ParserCallback
    
    var parser: XMLParser!
    
    var entries = [Entry]()
    var format: Format?
    var elementName: String?
    
    var entry: Entry?
    
    init(urlString: String, callback: @escaping Feeder.ParserCallback) {
        url = URL(string: urlString)!
        self.callback = callback
        super.init()
        
        let task = Feeder.shared.session.dataTask(with: url, completionHandler: { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    self.parser = XMLParser(data: data)
                    self.parser.delegate = self
                    self.parser.parse()
                } else {
                    self.callback([Entry](), error)
                }
            }
        }) 
        task.resume()
    }
    
    // MARK: NSXMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        switch (format, elementName) {
        case (_, "feed"):
            format = .atom
        case (_, "rss"):
            format = .rss
        case (_, "rdf:RDF"):
            format = .rdf
        case (.atom?, "entry"), (.rss?, "item"), (.rdf?, "item"):
            entry = Entry()
        case (.atom?, "link"):
            entry?.href = attributeDict["href"] ?? ""
        case (.atom?, "content"):
            entry?.summary = ""
            self.elementName = elementName
        case (.atom?, "summary"):
            if let summary = entry?.summary, summary.isEmpty {
                self.elementName = elementName
            }
        default:
            self.elementName = elementName
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch (format, elementName) {
        case (_, "title"?):
            entry?.title += string
        case (.rss?, "link"?), (.rdf?, "link"?):
            entry?.href += string
        case (.atom?, "content"?), (.atom?, "summary"?), (.rss?, "description"?), (.rdf?, "description"?):
            entry?.summary += string
       default:
            break
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        callback(entries, nil)
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        //print(parseError.localizedDescription)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        self.elementName = nil
        guard let entry = entry else { return }
        switch (format, elementName) {
        case (.atom?, "entry"), (.rss?, "item"), (.rdf?, "item"):
            entries.append(entry)
            self.entry = nil
        default:
            break
        }
    }
}

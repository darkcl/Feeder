//
//  Format.swift
//  Pods
//
//  Created by Tatsuya Tobioka on 11/19/15.
//
//

public enum Format {
    case atom, rss, rdf
    
    init?(contentType: String) {
        switch contentType {
        case "application/atom+xml":
            self = .atom
        case "application/rss+xml":
            self = .rss
        case "application/rdf+xml":
            self = .rdf
        default:
            return nil
        }
    }
}

//
//  NSErrorExtension.swift
//  App
//
//  Created by Balazs Szamody on 9/3/19.
//

import Vapor

extension NSError: Debuggable {
    public var identifier: String {
        return "domain: \(domain), code: \(code)"
    }
    
    public var reason: String {
        return "\(localizedDescription)"
    }
    
    
}

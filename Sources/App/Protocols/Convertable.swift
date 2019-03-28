//
//  Convertable.swift
//  App
//
//  Created by Balazs Szamody on 9/3/19.
//

import Foundation

protocol Convertable {}

extension Convertable where Self: Codable {
    func convert<T: Codable>(to type: T.Type) throws -> T {
        let data = try JSONEncoder().encode(self)
        print(String(data: data, encoding: .utf8))
        return try JSONDecoder().decode(T.self, from: data)
    }
}

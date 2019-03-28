//
//  AcronymTests.swift
//  App
//
//  Created by Balazs Szamody on 13/3/19.
//

@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class AcronymTests: XCTestCase {
    static let allTests = [
        ("testAcronymsCanBeRetrievedFromApi", testAcronymsCanBeRetrievedFromApi),
        ("testOneAcronymCanBeRetrievedFromApi", testOneAcronymCanBeRetrievedFromApi),
        ("testAcronymCanBeSearchedByShort", testAcronymCanBeSearchedByShort),
        ("testAcronymCanBeSearchedByLong", testAcronymCanBeSearchedByLong),
        ("testGetAcronymsSorted", testGetAcronymsSorted),
        ("testGetAcronymsFirst", testGetAcronymsFirst),
        ("testDeleteAcronym", testDeleteAcronym),
        ("testUpdateAcronym", testUpdateAcronym),
        ("testPatchAcronym", testPatchAcronym),
        ("testGetUserOfAcronym", testGetUserOfAcronym),
        ("testAddAcronymToCategory", testAddAcronymToCategory),
        ("testGetCategoriesForAcronym", testGetCategoriesForAcronym)
    ]
    
    var app: Application!
    var conn : PostgreSQLConnection!
    let url = "/api/acronyms/"
    var user: User!
    
    override func setUp() {
        super.setUp()
        try! Application.reset()
        app = try! Application.testable()
        conn = try! app.newConnection(to: .psql).wait()
        user = try! User.create(on: conn)
    }
    
    override func tearDown() {
        super.tearDown()
        conn.close()
        try? app.syncShutdownGracefully()
    }
    
    func testAcronymsCanBeRetrievedFromApi() throws {
        let expectedShort = "OMG"
        let expectedLong = "Oh my God"
        let acronym = try Acronym.create(short: expectedShort, long: expectedLong, user: user, on: conn)
        try Acronym.create(on: conn)
        
        let acronyms = try app.getResponse(to: url, decodeTo: [Acronym].self)
        
        XCTAssertEqual(acronyms.count, 2)
        XCTAssertEqual(acronyms[0].short, expectedShort)
        XCTAssertEqual(acronyms[0].long, expectedLong)
        XCTAssertEqual(acronyms[0].id, acronym.id)
    }
    
    func testOneAcronymCanBeRetrievedFromApi() throws {
        let expectedShort = "OMG"
        let expectedLong = "Oh my God"
        let acronymId = try Acronym.create(short: expectedShort, long: expectedLong, user: user, on: conn).id
        
        let acronym = try app.getResponse(to: "\(url)\(acronymId!)", decodeTo: Acronym.self)
        
        XCTAssertEqual(acronym.short, expectedShort)
        XCTAssertEqual(acronym.long, expectedLong)
        XCTAssertEqual(acronym.id, acronymId)
    }
    
    func testAcronymCanBeSearchedByShort() throws {
        let expectedShort = "OMG"
        let expectedLong = "Oh my God"
        let acronymId = try Acronym.create(short: expectedShort, long: expectedLong, user: user, on: conn).id
        
        let acronyms = try app.getResponse(to: "\(url)search?term=\(expectedShort)", decodeTo: [Acronym].self)
        
        XCTAssertEqual(acronyms.first?.short, expectedShort)
        XCTAssertEqual(acronyms.first?.long, expectedLong)
        XCTAssertEqual(acronyms.first?.id, acronymId)
    }
    
    func testAcronymCanBeSearchedByLong() throws {
        let expectedShort = "OMG"
        let expectedLong = "Oh my God"
        let acronymId = try Acronym.create(short: expectedShort, long: expectedLong, user: user, on: conn).id
        let params = expectedLong.replacingOccurrences(of: " ", with: "%20")
        let acronyms = try app.getResponse(to: "\(url)search?term=\(params)", decodeTo: [Acronym].self)
        
        XCTAssertEqual(acronyms.first?.short, expectedShort)
        XCTAssertEqual(acronyms.first?.long, expectedLong)
        XCTAssertEqual(acronyms.first?.id, acronymId)
    }
    
    func testGetAcronymsSorted() throws {
        let acronym1 = try Acronym.create(short: "OMG", long: "Oh My God", on: conn)
        let acronym2 = try Acronym.create(short: "AFK", long: "Away from Keyboard", on: conn)
        let acronym3 = try Acronym.create(short: "LoL", long: "Laugh out Load", on: conn)
        
        let sortedAcronymIDs = try app.getResponse(to: "\(url)sorted", decodeTo: [Acronym].self).map({ $0.id })
        let expectedIDs = [acronym1, acronym2, acronym3].sorted(by: { $0.short < $1.short }).map({ $0.id })
        XCTAssertEqual(sortedAcronymIDs, expectedIDs)
    }
    
    func testGetAcronymsFirst() throws {
        let expectedShort = "OMG"
        let expectedLong = "Oh my God"
        let acronymID = try Acronym.create(short: expectedShort, long: expectedLong, user: user, on: conn).id
        try Acronym.create(on: conn)
        
        let acronym = try app.getResponse(to: "\(url)first", decodeTo: Acronym.self)
        
        XCTAssertEqual(acronym.short, expectedShort)
        XCTAssertEqual(acronym.long, expectedLong)
        XCTAssertEqual(acronym.id, acronymID)
    }
    
    func testDeleteAcronym() throws {
        let expectedShort = "OMG"
        let expectedLong = "Oh my God"
        let acronymID = try Acronym.create(short: expectedShort, long: expectedLong, user: user, on: conn).id
        
        var acronym = try? app.getResponse(to: "\(url)\(acronymID!)", decodeTo: Acronym.self)
        
        XCTAssertNotNil(acronym)
        
        _ = try app.sendRequest(to: "\(url)\(acronymID!)", method: .DELETE)

        acronym = try? app.getResponse(to: "\(url)\(acronymID!)", decodeTo: Acronym.self)

        XCTAssertNil(acronym)
    }
    
    func testUpdateAcronym() throws {
        
        let expectedShort = "OMG"
        let expectedLong = "Oh my God"
        
        let savedAcronym = try Acronym.create(on: conn)
        let acronymId = savedAcronym.id ?? 0
        let userId = savedAcronym.userID
        
        let sutURL = "\(url)\(acronymId)"
        
        var acronym = try app.getResponse(to: sutURL, decodeTo: Acronym.self)
        
        XCTAssertEqual(acronym.short, "IDK")
        XCTAssertEqual(acronym.long, "I don't know")
        XCTAssertEqual(acronym.id, acronymId)
        
        let newAcronym = Acronym(short: expectedShort, long: expectedLong, userID: userId)
        
        _ = try app.sendRequest(to: sutURL, method: .PUT, body: newAcronym)
        
        acronym = try app.getResponse(to: sutURL, decodeTo: Acronym.self)
        
        XCTAssertEqual(acronym.short, expectedShort)
        XCTAssertEqual(acronym.long, expectedLong)
        XCTAssertEqual(acronym.id, acronymId)
    }
    
    func testPatchAcronym() throws {
        let expectedShort = "OMG"
        let expectedLong = "Oh my God"
        
        let acronymId = try Acronym.create(on: conn).id ?? 0
        let sutURL = "\(url)\(acronymId)"
        
        var acronym = try app.getResponse(to: sutURL, decodeTo: Acronym.self)
        
        XCTAssertEqual(acronym.short, "IDK")
        XCTAssertEqual(acronym.long, "I don't know")
        XCTAssertEqual(acronym.id, acronymId)
        
        let newBody: [String: String] = [
            "short": expectedShort,
            "long": expectedLong
        ]
        
        _ = try app.sendRequest(to: sutURL, method: .PATCH, body: newBody)
        
        acronym = try app.getResponse(to: sutURL, decodeTo: Acronym.self)
        
        XCTAssertEqual(acronym.short, expectedShort)
        XCTAssertEqual(acronym.long, expectedLong)
        XCTAssertEqual(acronym.id, acronymId)
    }
    
    func testGetUserOfAcronym() throws {
        let expectedName = "John Doe"
        let expetcedUsername = "john.doe"
        let savedUser = try User.create(name: expectedName, username: expetcedUsername, on: conn)
        
        let acronymID = try Acronym.create(user: savedUser, on: conn).id
        
        let user = try app.getResponse(to: "\(url)\(acronymID!)/user", decodeTo: User.self)
        
        XCTAssertEqual(user.name, expectedName)
        XCTAssertEqual(user.username, expetcedUsername)
        XCTAssertEqual(user.id, savedUser.id)
    }
    
    func testAddAcronymToCategory() throws {
        let acronymID = try Acronym.create(on: conn).id ?? 0
        
        let categoryID = try App.Category.create(on: conn).id ?? 0
        
        let route = "\(url)\(acronymID)/categories/"
        
        _ = try app.sendRequest(to: "\(route)\(categoryID)", method: .POST)
        
        let category = try app.getResponse(to: route, decodeTo: [App.Category].self).first
        
        XCTAssertEqual(category?.id, categoryID)
    }
    
    func testGetCategoriesForAcronym() throws {
        let expectedCategoryName = "Category1"
        
        let acronymID = try Acronym.create(on: conn).id ?? 0
        
        let route = "\(url)\(acronymID)/categories/"
        
        let category1ID = try Category.create(name: expectedCategoryName, on: conn).id ?? 0
        let category2ID = try Category.create(on: conn).id ?? 0
        
        _ = try app.sendRequest(to: "\(route)\(category1ID)", method: .POST)
        _ = try app.sendRequest(to: "\(route)\(category2ID)", method: .POST)
        
        let categories = try app.getResponse(to: route, decodeTo: [App.Category].self)
        
        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories.first?.name, expectedCategoryName)
        XCTAssertEqual(categories.first?.id, category1ID)
    }
}

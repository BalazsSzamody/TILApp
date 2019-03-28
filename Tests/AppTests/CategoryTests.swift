import Vapor
import FluentPostgreSQL
import XCTest
@testable import App

final class CategoryTests: XCTestCase {
    static let allTests = [
        ("testPostCategory", testPostCategory),
        ("testGetCategories", testGetCategories),
        ("testGetCategoryByID", testGetCategoryByID),
        ("testDeleteCategory", testDeleteCategory),
        ("testGetAcronymsForCategory", testGetAcronymsForCategory)
    ]
    
    var app: Application!
    var conn: PostgreSQLConnection!
    let url = "api/categories/"
    
    override func setUp() {
        super .setUp()
        try! Application.reset()
        app = try! Application.testable()
        conn = try! app.newConnection(to: .psql).wait()
    }
    
    override func tearDown() {
        super.tearDown()
        conn.close()
        try? app.syncShutdownGracefully()
    }
    
    func testPostCategory() throws {
        let expectedName = "Category"
        
        let category = try App.Category.create(name: expectedName, on: conn)
        
        XCTAssertEqual(category.name, expectedName)
        XCTAssertNotNil(category.id)
    }
    
    func testGetCategories() throws {
        let expectedName = "Category"
        var categories = try app.getResponse(to: url, decodeTo: [App.Category].self)
        
        XCTAssertEqual(categories.count, 0)
        let categoryID = try App.Category.create(name: expectedName, on: conn).id ?? 0
        
        _ = try App.Category.create(on: conn)
        
        categories = try app.getResponse(to: url, decodeTo: [App.Category].self)
        
        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories.first?.name, expectedName)
        XCTAssertEqual(categories.first?.id, categoryID)
    }
    
    func testGetCategoryByID() throws {
        let expectedName = "Category"
        let categoryID = try App.Category.create(name: expectedName, on: conn).id ?? 0
        
        let category = try app.getResponse(to: "\(url)\(categoryID)", decodeTo: App.Category.self)
        
        XCTAssertEqual(category.name, expectedName)
        XCTAssertEqual(category.id, categoryID)
    }
    
    func testDeleteCategory() throws {
        let categoryID = try App.Category.create(on: conn).id ?? 0
        let route = "\(url)\(categoryID)"
        var category = try? app.getResponse(to: route, decodeTo: App.Category.self)
        XCTAssertNotNil(category)
        
        _ = try app.sendRequest(to: route, method: .DELETE)
        
        category = try? app.getResponse(to: route, decodeTo: App.Category.self)
        XCTAssertNil(category)
    }
    
    func testGetAcronymsForCategory() throws {
        let expectedShort = "OMG"
        let expectedLong = "Oh My God"
        let categoryID = try App.Category.create(on: conn).id ?? 0
        let route = "\(url)\(categoryID)/acronyms"
        
        let acronym1ID = try Acronym.create(short: expectedShort, long: expectedLong, on: conn).id ?? 0
        let acronym2ID = try Acronym.create(on: conn).id ?? 0
        
        var acronyms = try app.getResponse(to: route, decodeTo: [Acronym].self)
        
        XCTAssertEqual(acronyms.count, 0)
        
        _ = try app.sendRequest(to: "api/acronyms/\(acronym1ID)/categories/\(categoryID)", method: .POST)
        _ = try app.sendRequest(to: "api/acronyms/\(acronym2ID)/categories/\(categoryID)", method: .POST)

        
        acronyms = try app.getResponse(to: route, decodeTo: [Acronym].self)
        
        XCTAssertEqual(acronyms.count, 2)
        XCTAssertEqual(acronyms.first?.short, expectedShort)
        XCTAssertEqual(acronyms.first?.long, expectedLong)
        XCTAssertEqual(acronyms.first?.id, acronym1ID)
    }
}


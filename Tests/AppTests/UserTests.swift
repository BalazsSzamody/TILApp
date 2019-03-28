@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class UserTests: XCTestCase {


    static let allTests = [
        ("testUsersCanBeRetrievedFromApi", testUsersCanBeRetrievedFromApi),
        ("testUserCanBeSavedWithAPI", testUserCanBeSavedWithAPI),
        ("testGettingASingleUserFromTheApi", testGettingASingleUserFromTheApi),
        ("testGettingAUsersAcronymsFromTheAPI", testGettingAUsersAcronymsFromTheAPI)
    ]

    let usersName = "Alice"
    let usersUsername = "alicea"
    let usersURL = "/api/users/"
    var app: Application!
    var conn: PostgreSQLConnection!


    override func setUp() {
        super.setUp()
        try! Application.reset()
        app = try! Application.testable()
        conn = try! app.newConnection(to: .psql).wait()
    }

    override func tearDown() {
        super.tearDown()
        conn.close()
        try? app.syncShutdownGracefully()
    }

    func testUsersCanBeRetrievedFromApi() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: conn)
        XCTAssertEqual(user.name, usersName)
        XCTAssertEqual(user.username, usersUsername)
        _ = try User.create(on: conn)

        let users = try app.getResponse(to: usersURL, decodeTo: [User].self)

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].name, usersName)
        XCTAssertEqual(users[0].username, usersUsername)
        XCTAssertEqual(users[0].id, user.id)
    }
    
    func testUserCanBeSavedWithAPI() throws {
        let user = User(name: usersName, username: usersUsername)
        
        let receivedUser = try app.getResponse(to: usersURL, method: .POST, headers: ["Content-Type": "application/json"], data: user, decodeTo: User.self)
        
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertNotNil(receivedUser.id)
        
        let users = try app.getResponse(to: usersURL, decodeTo: [User].self)
        
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users[0].name, usersName)
        XCTAssertEqual(users[0].username, usersUsername)
        XCTAssertEqual(users[0].id, receivedUser.id)
    }
    
    func testGettingASingleUserFromTheApi() throws {
        
        let user = try User.create(name: usersName, username: usersUsername, on: conn)
        
        let receivedUser = try app.getResponse(to: "\(usersURL)\(user.id!)", decodeTo: User.self)
        
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertEqual(receivedUser.id, user.id)
    }
    
    func testGettingAUsersAcronymsFromTheAPI() throws {
        let user = try User.create(on: conn)
        
        let acronymShort = "OMG"
        let acronymLong = "Oh my God!"
        
        let savedAronym = try Acronym.create(short: acronymShort, long: acronymLong, user: user, on: conn)
        
        _ = try Acronym.create(short: "LoL", long: "Laugh out Loud", user: user, on: conn)
        
        _ = try Acronym.create(user: user, on: conn)
        
        let acronyms = try app.getResponse(to: "\(usersURL)\(user.id!)/acronyms", decodeTo: [Acronym].self)
        
        XCTAssertEqual(acronyms.count, 3)
        XCTAssertEqual(acronyms.first?.short, acronymShort)
        XCTAssertEqual(acronyms.first?.long, acronymLong)
        XCTAssertEqual(acronyms.first?.id, savedAronym.id)
        
    }
}

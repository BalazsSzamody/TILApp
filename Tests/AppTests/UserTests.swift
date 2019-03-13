@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class UserTests: XCTestCase {


    static let allTests = [
        ("testUsersCanBeRetrievedFromApi", testUsersCanBeRetrievedFromApi)
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
}

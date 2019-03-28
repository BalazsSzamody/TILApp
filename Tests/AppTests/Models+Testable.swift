@testable import App
import FluentPostgreSQL

extension User {
    @discardableResult
    static func create(
        name: String = "Luke",
        username: String = "lukes",
        on connection: PostgreSQLConnection
        ) throws -> User {
        let user = User(name: name, username: username)
        
        return try user.save(on: connection).wait()
    }
}

extension Acronym {
    @discardableResult
    static func create(
        short: String = "IDK",
        long: String = "I don't know",
        user: User? = nil,
        on connection: PostgreSQLConnection
        ) throws -> Acronym {
        var user = user
        
        if user == nil {
            user = try User.create(on: connection)
        }
        
        let acronym = Acronym(short: short, long: long, userID: user!.id!)
        
        return try acronym.save(on: connection).wait()
    }
}

extension App.Category {
    @discardableResult
    static func create(name: String = "Random", on connection: PostgreSQLConnection) throws -> App.Category {
        let category = Category(name: name)
        return try category.save(on: connection).wait()
    }
}

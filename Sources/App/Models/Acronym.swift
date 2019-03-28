import Vapor
//import FluentMySQL
import FluentPostgreSQL

final class Acronym: NSObject, Codable {
    var id: Int?
    var short: String
    var long: String
    var userID: User.ID
    
    init(short: String, long: String, userID: User.ID) {
        self.short = short
        self.long = long
        self.userID = userID
    }
    
    func setContent(from acronym: Acronym) {
        self.short = acronym.short
        self.long = acronym.long
    }
}
//extension Acronym: MySQLModel {}
extension Acronym: PostgreSQLModel {}

extension Acronym: Content {}

// This makes Acronym queryable
extension Acronym: Parameter {}

extension Acronym: Convertable {}

extension Acronym {
    var user: Parent<Acronym, User> {
        return parent(\.userID)
    }
    
    var categories: Siblings<Acronym, Category, AcronymCategoryPivot> {
        return siblings()
    }
}

extension Acronym: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection, closure: { (builder) in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        })
    }
}

// General database extension
//extension Acronym: Model {
//    typealias Database = SQLiteDatabase
//    typealias ID = Int
//    public static var idKey:IDKey = \Acronym.id
//}


//import FluentSQLite
//import FluentMySQL
import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
//    try services.register(FluentSQLiteProvider())
//    try services.register(FluentMySQLProvider())
    try services.register(FluentPostgreSQLProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    // Non-Presistent Database
//    let sqlite = try SQLiteDatabase(storage: .memory)
    
    //Presistent Database
//    let sqlite = try SQLiteDatabase(storage: .file(path: "db.sqlite"))

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
//    let databaseConfig = MySQLDatabaseConfig(hostname: "db",
//                                             username: "test",
//                                             password: "test",
//                                             database: "test")
//    let database = MySQLDatabase(config: databaseConfig)
    let databaseHost: String
    let databaseName: String
    let databasePort: Int
    let databaseUsername: String
    let password: String?
    
    switch env {
    case .testing:
        databaseHost = "localhost"
        databaseName = "testdb"
        databasePort = 5433
        databaseUsername = "testing"
        password = "password"
    default:
        databaseHost = "db"
        databaseName = "postgres"
        databasePort = 5432
        databaseUsername = "staging"
        password = "password"
    }
    let databaseConfig = PostgreSQLDatabaseConfig(hostname: databaseHost,
                                                  port: databasePort,
                                                  username: databaseUsername,
                                                  database: databaseName,
                                                  password: password)
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)

    // Configure migrations
    var migrations = MigrationConfig()
    // User created first, because Acronym relies on User
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Acronym.self, database: .psql)
    migrations.add(model: Category.self, database: .psql)
    migrations.add(model: AcronymCategoryPivot.self, database: .psql)
    services.register(migrations)
    
    // Test config
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)
}

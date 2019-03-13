import Vapor
import Fluent
import FluentPostgreSQL

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    // Registering AcronymsController
    let acronymsController = AcronymsController()
    try router.register(collection: acronymsController)
    
    // Registering UsersController
    let usersController = UsersController()
    try router.register(collection: usersController)
    
    // Registering CategoriesController
    let categoriesController = CategoriesController()
    try router.register(collection: categoriesController)
}

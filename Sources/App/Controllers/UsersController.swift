import Vapor

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        
        usersRoute.post(User.self, use: createHandler)
        usersRoute.get(User.parameter, use: getHandler)
        usersRoute.get(use: getAllHandler)
        usersRoute.get(User.parameter, "acronyms", use: getAcronymsHandler)
        usersRoute.delete(User.parameter, use: deleteHandler)
    }
    
    func createHandler(_ req: Request, user: User) throws -> Future<User> {
        return user.save(on: req)
    }
    
    func getHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(User.self)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User]> {
        return User
            .query(on: req)
            .all()
    }
    
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req
            .parameters
            .next(User.self)
            .flatMap(to: [Acronym].self, { (user) in
                return try user
                    .acronyms
                    .query(on: req)
                    .all()
            })
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(User.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
    
}

import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        
        acronymsRoutes.get(use: getAllHandler)
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        acronymsRoutes.get("search", use: searchHandler)
        acronymsRoutes.get("sorted", use: sortedHandler)
        acronymsRoutes.get("first", use: firstHandler)
        acronymsRoutes.post(Acronym.self, use: createHandler)
        acronymsRoutes.patch(Acronym.parameter, use: patchHandler)
        acronymsRoutes.delete(Acronym.parameter, use: deleteHandler)
        acronymsRoutes.put(Acronym.parameter, use: updateHandler)
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        
        let acronymsCategoriesRoutes = acronymsRoutes.grouped(Acronym.parameter, "categories")
        
        acronymsCategoriesRoutes.post(Category.parameter, use: addCategoriesHandler)
        acronymsCategoriesRoutes.get(use: getCategoriesHandler)
        acronymsCategoriesRoutes.delete(Category.parameter, use: removeCategoriesHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req
            .parameters
            .next(Acronym.self)
    }
    
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Acronym.query(on: req)
            .group(.or, closure: { (or) in
                or.filter(\.short == searchTerm)
                or.filter(\.long == searchTerm)
                //                or.filter(\.long, .contains, searchTerm)
            })
            .all()
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym
            .query(on: req)
            .sort(\.short, .ascending)
            .all()
    }
    
    func firstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym
            .query(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
    }
    
    func createHandler(_ req : Request, acronym: Acronym) throws -> Future<Acronym> {
        return acronym.save(on: req)
    }
    
    func deleteHandler(_ req : Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(Acronym.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
    
    func patchHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(req.parameters.next(Acronym.self),
                           req.content.decode([String: String].self),
                           { (acronym, payload) -> Future<Acronym> in
                            var acronymDict = try acronym.convert(to: [String: String].self)
                            
                            payload.forEach({ (key, value) in
                                acronymDict[key] = value
                            })
                            let patchedAcronym = try acronymDict.convert(to: Acronym.self)
                            acronym.setContent(from: patchedAcronym)
                            
                            return acronym.save(on: req)
                    })
    }
    
    func updateHandler(_ req : Request) throws -> Future<Acronym> {
        return try flatMap(
            to: Acronym.self,
            req.parameters.next(Acronym.self),
            req.content.decode(Acronym.self)
            ) { (acronym, updatedAcronym) in
                acronym.short = updatedAcronym.short
                acronym.long = updatedAcronym.long
                acronym.userID = updatedAcronym.userID
                return acronym.save(on: req)
            }
    }
    
    func getUserHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(Acronym.self)
            .flatMap(to: User.self, { (acronym) in
                acronym.user.get(on: req)
            })
    }
    
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(Acronym.self),
                           req.parameters.next(Category.self), { (acronym, category) in
                            return acronym
                                .categories
                                .attach(category, on: req)
                                .transform(to: .created)
                    })
    }
    
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req
            .parameters
            .next(Acronym.self)
            .flatMap(to: [Category].self, { (acronym) in
                try acronym
                    .categories
                    .query(on: req)
                    .all()
            })
    }
    
    func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(Acronym.self),
                           req.parameters.next(Category.self),
                           { (acronym, category) in
                            return acronym
                                .categories
                                .detach(category, on: req)
                                .transform(to: .noContent)
                    })
    }
}

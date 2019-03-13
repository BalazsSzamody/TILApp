import Vapor

struct CategoriesController: RouteCollection {
    func boot(router: Router) throws {
        let categoriesRoute = router.grouped("api", "categories")
        
        categoriesRoute.post(Category.self, use: createHandler)
        categoriesRoute.get(Category.parameter, use: getHandler)
        categoriesRoute.get(use: getAllHandler)
        categoriesRoute.delete(Category.parameter, use: deleteHandler)
        categoriesRoute.get(Category.parameter, "acronyms", use: getAcronymsHandler)
    }
    
    func createHandler(_ req: Request, category: Category) throws -> Future<Category> {
        return category.save(on: req)
    }
    
    func getHandler(_ req: Request) throws -> Future<Category> {
        return try req.parameters.next(Category.self)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Category]> {
        return Category
            .query(on: req)
            .all()
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req
            .parameters
            .next(Category.self)
            .delete(on: req)
            .transform(to: .noContent)
    }
    
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req
            .parameters
            .next(Category.self)
            .flatMap(to: [Acronym].self, { (category) in
                return try category
                    .acronyms
                    .query(on: req)
                    .all()
            })
    }
}

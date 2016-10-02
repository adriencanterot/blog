import Vapor
import HTTP
import Auth
import Turnstile

final class UserController: ResourceRepresentable {
    
    let drop:Droplet
    
    public init(droplet: Droplet) {
        self.drop = droplet
    }
    
    func index(request: Request) throws -> ResponseRepresentable {
        return try User.all().makeNode().converted(to: JSON.self)
    }
    
    func create(request: Request) throws -> ResponseRepresentable {
        
        var user = try User(with: request)
        
        guard user.password == request.data["confirm"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Non matching passwords")
        }
        
        guard try User.query().filter("name", user.name).first() == nil else {
            throw Abort.custom(status: .badRequest, message: "User already exists")
        }
        try user.save()
        return Response(redirect: "users/")
    }
    
    func show(request: Request, user: User) throws -> ResponseRepresentable {
        return user
    }
    
    func delete(request: Request, user: User) throws -> ResponseRepresentable {
        try user.delete()
        return JSON([:])
    }
    
    func login(request: Request) throws -> ResponseRepresentable {
        guard let username = request.data["username"]?.string, let password = request.data["password"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Incomplete credentials")
        }
        
        let pair =  UsernamePassword(username: username, password: password)
        try request.auth.login(pair)
        return Response(redirect: "users")
    }
    
    
    func makeResource() -> Resource<User> {
        return Resource(
            index: index,
            store: create,
            show: show,
            destroy: delete
        )
    }
}

extension User {
    
    public convenience init(with request:Request) throws {
        
        guard let name = request.data["username"]?.string,
              let email = request.data["email"],
              let password = request.data["password"]?.string else {
                
            throw Abort.custom(status: .badRequest, message: "Input not conform")
        }
        
        try self.init(name:name, email:email.validated(), password:password)
    }

}

extension Request {
    func user() throws -> User {
        guard let user = try auth.user() as? User else {
            throw Abort.custom(status: .badRequest, message: "Wrong user type")
        }
        
        return user
    }
}

import Vapor
import Auth
import Turnstile

final class User:Model {
    
    var id:Node?
    
    var name:String
    var email:Valid<Email>
    var password: String
    
    var exists: Bool = false
        
    public init(name:String, email:Valid<Email>, password:String) {
        self.name = name
        self.email = email
        self.password = password
    }
    
    public init(node: Node, in context: Context) throws {
        self.id = try node.extract("id")
        self.name = try node.extract("name")
        let rawEmail: String = try node.extract("email")
        self.email = try rawEmail.validated()
        self.password = try node.extract("password")
        let mirror = Mirror(reflecting: self.self)
        for child in mirror.children {
            print(child.label!)
        }
    }
    
    func makeNode(context: Context) throws -> Node {
        
        return try Node(node: [
            "id":self.id,
            "name":self.name,
            "email": self.email.value,
            "password": self.password
            ]
        )
        
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(entity) { builder in
            builder.id()
            builder.string("name")
            builder.string("email")
            builder.string("password")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(entity)
    }
}

extension User:Auth.User {
    
    public static func authenticate(credentials: Credentials) throws -> Auth.User {
        
        var user:User?
        
        switch credentials {
        case let id as Identifier:
            user = try User.find(id.id)
        case let usernamePassword as UsernamePassword:
            user = try User.query().filter("name", usernamePassword.username)
                .filter("password", usernamePassword.password).first()
            
        default:
            throw Abort.custom(status: .badRequest, message: "Invalid credentials")
        }
        
        guard let u = user else {
            throw Abort.custom(status: .badRequest, message: "User not found")
        }
        
        return u
    }
    
    public static func register(credentials: Credentials) throws -> Auth.User {
        
        guard let  usernamePasswordPair = credentials as? UsernamePassword else {
            throw Abort.custom(status: .forbidden, message: "Invalid credentials")
        }
        
        return User(name: usernamePasswordPair.username, email: try "email@email.com".validated(by: Email.self), password: usernamePasswordPair.password)
        
    }
}




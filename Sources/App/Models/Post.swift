import Vapor
import Fluent

final class Post: Model {
    var id: Node?
    var authorId: Node?
    var content: String
    var title: String
    
    var exists: Bool = false
    
    init(title:String, content: String, userId:Node? = nil) {
        self.content = content
        self.title = title
        self.authorId = userId
    }
    
    public convenience init(title: String, content: String, user: User?) {
        self.init(title:title, content:content, userId: user?.id)
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        authorId = try node.extract("user_id")
        content = try node.extract("content")
        title = try node.extract("title")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "user_id": authorId,
            "title": title,
            "content": content
        ])
    }
    
    func format() throws -> Node {
        return try Node(node: [
            "id": id,
            "user": try user()?.makeNode(),
            "title": title,
            "content": content
            ])
    }
}

extension Post {
    func user() throws -> User? {
        return try parent(authorId).get()
    }
}

extension Post: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(entity) { creator in
            creator.id()
            creator.parent(User.self)
            creator.string("title")
            creator.string("content")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(entity)
    }
}

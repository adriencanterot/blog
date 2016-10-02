import Vapor
import HTTP

final class PostController: ResourceRepresentable {
    
    let drop:Droplet
    
    public init(droplet: Droplet) {
        self.drop = droplet
    }
    
    func index(request: Request) throws -> ResponseRepresentable {
        let posts = try Post.all().map { try $0.format() }
        return try drop.view.make("posts/posts.leaf", ["posts": posts.makeNode()])
    }

    func create(request: Request) throws -> ResponseRepresentable {
        var post = try Post(with: request)
        try post.save()
        return try post.makeJSON()
    }

    func show(request: Request, post: Post) throws -> ResponseRepresentable {
        return post
    }

    func delete(request: Request, post: Post) throws -> ResponseRepresentable {
        try post.delete()
        return JSON([:])
    }

    func update(request: Request, post: Post) throws -> ResponseRepresentable {
        
        return post
    }


    func makeResource() -> Resource<Post> {
        return Resource(
            index: index,
            store: create,
            show: show,
            modify: update,
            destroy: delete
        )
    }
}

extension Post {
    public convenience init(with request:Request) throws {
        
        guard let title = request.data["title"]?.string,
              let content = request.data["content"]?.string else {
                
                throw Abort.custom(status: .badRequest, message: "Input not conform")
        }
        
        self.init(title:title, content:content, user:try request.user())
    }
}

import Vapor
import VaporSQLite
import Turnstile
import Auth
import HTTP

let authMiddleware = AuthMiddleware(user: User.self)

let drop = Droplet(availableMiddleware:["auth": authMiddleware], preparations:[User.self, Post.self], providers:[VaporSQLite.Provider.self])

drop.get { req in
    let lang = req.headers["Accept-Language"]?.string ?? "en"
    return try drop.view.make("welcome", [
    	"message": Node.string(drop.localization[lang, "welcome", "title"])
    ])
}

let postController = PostController(droplet: drop)

drop.resource("posts", postController)


let userController = UserController(droplet: drop)
//drop.resource("users", userController)

drop.get("login") { _ in
    return try drop.view.make("Users/login.leaf")
}

drop.post("login") { request in
    return try userController.login(request: request)
}

drop.get("register") { _ in
    return try drop.view.make("Users/register.leaf")
}

drop.get("logout") { request in
    
    try request.auth.logout()
    return JSON([:])
}

let protect = ProtectMiddleware(error: Abort.custom(status: .forbidden, message: "User not authenticated"))

drop.group(protect) { secure in
    secure.resource("users", userController)
    secure.get("posts/new") { request in
        return try drop.view.make("Posts/new.leaf")
    }
}


drop.run()

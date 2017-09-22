import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import Foundation 

let lightingController = LightingController()
lightingController.start()

// Create HTTP server
let server = HTTPServer()

// Set the server's webroot
server.documentRoot = "./webroot"

// Add our routes and such
// let routes = makeRoutes()
// server.addRoutes(routes)

// Listen on port 8181
server.serverPort = 8181

do {
    // Launch the HTTP server on port 8181
    try server.start()    
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}

print("finished")

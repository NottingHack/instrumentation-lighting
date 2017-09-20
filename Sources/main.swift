import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import Aphid
import Foundation 

let serviceName = "nh-lighting"

let client = MqttClient(clientId: serviceName)

// config.host = "192.168.0.1"
// config.host = "127.0.0.1"

do {
    try client.connect()
} catch let error {
    print("\(error)")
}

client.publish(topic: "nh/status/res", withMessage: "Restart: \(serviceName)", qos: .atMostOnce)
client.subscribe(topic: ["nh/status/req", "nh/li/+/+/state"], qoss: [.atMostOnce, .atMostOnce])


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

// client.disconnect()

while config.status == ConnectionStatus.connected {
    sleep(60)
}
print("finished")

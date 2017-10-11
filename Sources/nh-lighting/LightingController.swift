//
//  LightingController.swift
//  instrumentation-lighting
//
//  Created by Matt Lloyd on 21/09/2017.
//
//

import Foundation
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import Configuration
import PerfectWebSockets


// MARK: -
class LightingController {
  
  let serviceName: String
  
  let manager = ConfigurationManager()
  
  let mysql: MySQLService
  let mqtt: MqttService
  let http = HTTPServer()
  let wsClients: [LightingClient: WebSocket] = [:]
  
  init() {
    Log.info(message: "nh-lighting: Starting")
    #if Xcode
      let configPath = "../../config.json"
    #else
      let configPath = "../../../config.json"
    #endif
    
    manager.load(file: configPath).load(.environmentVariables).load(.commandLineArguments)
    serviceName = manager["serviceName"] as! String
    
    mysql = MySQLService(host: manager["mysql:host"] as! String, user: manager["mysql:user"] as! String, password: manager["mysql:password"] as! String, database: manager["mysql:database"] as! String)
    
    mqtt = MqttService(clientId: serviceName, host: manager["mqtt:host"] as! String, port: manager["mqtt:port"] as! Int32)
    mqtt.stateDelagate = self
    
    if let documentRoot = manager["http:documentRoot"] as! String? {
      http.documentRoot = documentRoot
    }
    
    if let address = manager["http:address"] as! String? {
      http.serverAddress = address
    }
    
    if let port = manager["http:port"] as? UInt16? ?? 8181 {
      http.serverPort = port
    }
    
    http.addRoutes(makeRoutes())
  }
  
  func start() {
    
    guard mysql.loadModels() else {
      Log.error(message: "Failed to load models")
      // TODO: try agian or quit
      return
    }
    
    do {
      try mqtt.connect()
    } catch let error {
      Log.error(message: "Mqtt failed to connect with \(error)")
      // TODO: try again?
    }

    
    do {
      // Launch the HTTP server on port 8181
      try http.start()
    } catch PerfectError.networkError(let err, let msg) {
      Log.error(message: "Network error thrown: \(err) \(msg)")
    } catch let error {
      Log.error(message: "\(error)")
    }
  }
  
  func makeRoutes() -> Routes {
    var routes = Routes()
    
    routes.add(method: .get, uri: "/lighting", handler: {
      request, response in
        WebSocketHandler(handlerProducer: {
        (request: HTTPRequest, protocols: [String]) -> WebSocketSessionHandler? in
          
        // Check to make sure the client is requesting our "echo" service.
        guard protocols.contains("lighting") else {
          return nil
        }
        
        // Return our service handler.
        return LightingHandler()
      }).handleRequest(request: request, response: response)
    })
    
    return routes
  }
  
  func findLights(forChannel channel: Int, fromController controllerName: String) -> [Light]? {
    var lights: [Light]?
    if let controller = lighting.controllers.first(where: {$0.name == controllerName}),
      let channel = lighting.outputChannels.first(where: {$0.controllerId == controller.id && $0.channel == channel}) {
      lights = lighting.lights.filter {
          $0.outputChannelId == channel.id
      }
      
    }
    
    return lights
  }
}

// MARK: - ControllerStateDelagate
extension LightingController: ControllerStateDelagate {
  func didRecieve(_ state: ChannelState, forChannel channel: String, fromController controllerName: String) {
    Log.info(message: "\(controllerName, channel, state)")
    
    if channel.contains("I") {
      // deal with input channel
      
      return
    }
    
    guard let lights = findLights(forChannel: Int(channel)!, fromController: controllerName) else {
      return
    }
    
    for light in lights {
      // post out new state to WS
      print(light)
    }
  }
}

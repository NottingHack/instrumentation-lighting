//
//  LightingController.swift
//  instrumentation-lighting
//
//  Created by Matt Lloyd on 21/09/2017.
//
//

import Foundation
import Dispatch
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
  var wsClients: [LightingClient: WebSocket] = [:]
  var sockets: [WebSocket] = []
  
  var currentStates = [CurrentLightState]()
  let processQueue: DispatchQueue
  
  init() {
    Log.info(message: "nh-lighting: Starting")
    var configPath = "./config.json"

    if _isDebugAssertConfiguration() {
      #if Xcode
        configPath = "../../config.json"
      #else
        configPath = "../../../config.json" // location for use with SwitPM
      #endif
    }
    
    manager.load(file: configPath).load(.environmentVariables).load(.commandLineArguments)
    serviceName = manager["serviceName"] as! String
    
    processQueue = DispatchQueue(label: "\(serviceName).process")
    
    mysql = MySQLService(host: manager["mysql:host"] as! String, user: manager["mysql:user"] as! String, password: manager["mysql:password"] as! String, database: manager["mysql:database"] as! String)
    
    mqtt = MqttService(clientId: serviceName, host: manager["mqtt:host"] as! String, port: Int32(manager["mqtt:port"] as! Int))
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
        return LightingHandler(delegate: self)
      }).handleRequest(request: request, response: response)
    })
    
    return routes
  }
  
  func reload() {
    Log.info(message: "Caught SIGHUP")
    guard mysql.loadModels() else {
      Log.error(message: "Failed to reload models")
      // TODO: try agian or quit
      return
    }
    
    // TODO: let clients know they need to reconnet? or to wipe and reload there description
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
  
  func updateLightState(lightId: Int, newState state: ChannelState) {
    if let lightState = currentStates.first(where: {$0.id == lightId}) {
      lightState.state = state
    } else {
      currentStates.append(CurrentLightState(id: lightId, state: state))
    }
  }
  
  func findControllerAndOutputChannel(forEvent event: RequestEvent) -> (controller: Controller, outputChannel: OutputChannel)? {
    if let lightId = event.light,
       let light = lighting.lights.first(where: {$0.id == lightId}),
       let outputChannel = lighting.outputChannels.first(where: {$0.id == light.outputChannelId}),
       let controller = lighting.controllers.first(where: {$0.id == outputChannel.controllerId}) {
      return (controller, outputChannel)
    }
    return nil
  }
  
  func clientConnected(fromSocket socket: WebSocket) {
    describeRooms(toSocket: socket)
    describeCurrentStates(toSocket: socket)
    describePatterns(toSocket: socket)
  }
  
  func describeRooms(toSocket socket: WebSocket) {
    var roomDescriptionEvents: [RoomDescriptionEvent] = []
    for room in lighting.rooms {
      let lights = lighting.lights.filter({ $0.roomId == room.id})
      var lightIds: [Int] = []
      for light in lights {
        lightIds.append(light.id)
      }
      let roomDescription = RoomDescriptionEvent(room: room.name, lights:lightIds)
      roomDescriptionEvents.append(roomDescription)
    }
    
    do {
      let jsonEvent = try JSONEncoder().encode(roomDescriptionEvents)
      socket.sendStringMessage(string: String(data: jsonEvent, encoding: .utf8)!, final: true) {
        
      }
    } catch {
      
    }
  }
  
  func describeCurrentStates(toSocket socket: WebSocket) {
    var lightStateEvents: [LightStateEvent] = []
    for lightState in currentStates {
      if let light = lighting.lights.first(where: {$0.id == lightState.id}),
         let room = lighting.rooms.first(where: {$0.id == light.roomId}) {
        let lightStateEvent = LightStateEvent(room: room.name, light: light.id, state: lightState.state)
        lightStateEvents.append(lightStateEvent)
      }
    }
    
    do {
      let jsonEvent = try JSONEncoder().encode(lightStateEvents)
      socket.sendStringMessage(string: String(data: jsonEvent, encoding: .utf8)!, final: true) {
        
      }
    } catch {
      
    }
  }
  
  func describePatterns(toSocket socket: WebSocket) {
    var patternDescriptionEvents: [PatternDescrptionEvent] = []
    
    for pattern in lighting.patterns {
      var lightStates: [PatternDescrptionEvent.LightState] = []
      let lightPatterns = lighting.lightPatterns.filter({$0.patternId == pattern.id})
      for lightPattern in lightPatterns {
        if let light = lighting.lights.first(where: {$0.id == lightPattern.lightId}),
           let room = lighting.rooms.first(where: {$0.id == light.roomId}) {
          let lightState = PatternDescrptionEvent.LightState(room: room.name, light: light.id, state: lightPattern.state)
          lightStates.append(lightState)
        }
      }
      
      let roomDescription = PatternDescrptionEvent(patternId: pattern.id, name: pattern.name, lights: lightStates)
      patternDescriptionEvents.append(roomDescription)
    }
    
    do {
      let jsonEvent = try JSONEncoder().encode(patternDescriptionEvents)
      socket.sendStringMessage(string: String(data: jsonEvent, encoding: .utf8)!, final: true) {
        
      }
    } catch {
      
    }
  }
  
  func processLight(request: RequestEvent, forSocket socket: WebSocket) {
    guard let state = request.state,
      let (controller, outputChannel) = findControllerAndOutputChannel(forEvent: request) else {
        Log.warning(message: "Incomplete LightRequest: \(request)")
        return
    }
    
    // TODO: Check client has permission to make this request
    mqtt.request(newState: state, forOutputChannel: outputChannel, onController: controller)
  }
  
  func processPattern(patternId: Int) {
    if let pattern = lighting.patterns.first(where: {$0.id == patternId}){
      let lightPatterns = lighting.lightPatterns.filter({$0.patternId == pattern.id})
      // send out mqtt request for each light in the pattern
      for lightPattern in lightPatterns {
        if let light = lighting.lights.first(where: {$0.id == lightPattern.lightId}),
           let outputChannel = lighting.outputChannels.first(where: {$0.id == light.outputChannelId}),
           let controller = lighting.controllers.first(where: {$0.id == outputChannel.controllerId}) {
          // TODO: Check client has permission to make this request
          self.mqtt.request(newState: lightPattern.state, forOutputChannel: outputChannel, onController: controller)
        }
      }
      // now check to see if we need to schedule a call to procees the next patttern
      if let nextPatternId = pattern.nextPatternId,
         let timeout = pattern.timeout {
        let timeoutSeconds = Double(timeout) / 1000.0
        processQueue.asyncAfter(deadline: .now() + timeoutSeconds) {
          self.processPattern(patternId: nextPatternId)
        }
      }
    }
  }
  
  func processPattern(request: RequestEvent, forSocket socket: WebSocket) {
    if let patternId = request.patternId {
      processPattern(patternId: patternId)
    }
  }
    
  func processPattern(forChannel channel: Int, fromController controller: String, withState state: ChannelState) {
    if (state == .ON) {
      if let inputChannel = lighting.inputChannels.first(where: {$0.channel == channel}),
         let patternId = inputChannel.patternId {
        processPattern(patternId: patternId)
      }
    }
  }
}

// MARK: - ControllerStateDelagate
extension LightingController: ControllerStateDelagate {
  func didReceive(_ state: ChannelState, forChannel channel: String, fromController controllerName: String) {
    processQueue.async {
      Log.info(message: "didReceive message: \(controllerName, channel, state)")
      
      if channel.contains("I") {
        // deal with input channel
        var inputChannel = channel
        inputChannel.removeFirst()
        self.processPattern(forChannel: Int(inputChannel)!, fromController: controllerName, withState: state)
        return
      }
      
      guard let lights = self.findLights(forChannel: Int(channel)!, fromController: controllerName) else {
        return
      }
      
      for light in lights {
        self.updateLightState(lightId: light.id, newState: state)
        // post out new state to WS

        guard let room = lighting.rooms.first(where: {$0.id == light.roomId}) else {
            Log.error(message: "didReveive: Can not find room for light: \(light)")
            continue
        }
        
        let lightStateEvent = LightStateEvent(room: room.name, light: light.id, state: state)
        
        do {
          let jsonEvent = try JSONEncoder().encode(lightStateEvent)
          // TODO: use the wsClients dict when we start filling it
          for socket in self.sockets {
            // TODO: dispatch to an concurrent async queue?
            socket.sendStringMessage(string: String(data: jsonEvent, encoding: .utf8)!, final: true) {
                
            }
          }
        } catch {
            
        }
      }
    }
  }
}

// MARK: - LightingHandlerDelage
extension LightingController: LightingHandlerDelegate {
  func addClientIfNeed(_ handler: WebSocketSessionHandler, request: HTTPRequest, socket: WebSocket, callback: @escaping (Bool) -> ()) {
    Log.info(message: "addClient: \(handler, request, socket)")
    // TODO: use wsClients dict
    if (!sockets.contains(socket)) {
      sockets.append(socket)
    }
    callback(true)
  }
  
  func removeClient(_ socket: WebSocket, callback: @escaping (Bool) -> ()) {
    Log.info(message: "removeClient: \(socket)")
    // TODO: use wsClients dict
    if let socketIndex = sockets.index(of: socket) {
      sockets.remove(at: socketIndex)
    }
    callback(true)
  }
  
  func processRequestMessage(_ socket: WebSocket, event: RequestEvent) {
    processQueue.async {
      Log.info(message: "processRequestMessage: \(event)")
      switch event.eventType {
      case .ConnectRequest:
        // send out description and current states
        self.clientConnected(fromSocket: socket)
      case .LightRequest:
        // need to send out via mqtt
        self.processLight(request: event, forSocket: socket)
      case .PatternRequest:
        print("processRequest: pattern")
        // need to look up and send out bunch of mqtt stuff
        self.processPattern(request: event, forSocket: socket)
      }
    }
  }
}

//
//  LightingController.swift
//  instrumentation-lighting
//
//  Created by Matt Lloyd on 21/09/2017.
//
//

import Foundation
import PerfectLib
import Configuration


enum ChannelState: String {
  case ON
  case OFF
  case TOGGLE
}

// MARK: -
class LightingController {
  
  let serviceName: String
  
  let manager = ConfigurationManager()
  
  let mysql: MySQLService
  let mqtt: MqttService
  
  init() {
    manager.load(file: "../../config.json").load(.environmentVariables).load(.commandLineArguments)
    serviceName = manager["serviceName"] as! String
    
    mysql = MySQLService(host: manager["mysql:host"] as! String, user: manager["mysql:user"] as! String, password: manager["mysql:password"] as! String, database: manager["mysql:database"] as! String)
    
    mqtt = MqttService(clientId: serviceName, host: manager["mqtt:host"] as! String, port: manager["mqtt:port"] as! Int32)
    mqtt.stateDelagate = self
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

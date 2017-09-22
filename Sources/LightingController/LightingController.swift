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

protocol MySQLHandler: class {
}

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
        do {
            try mqtt.connect()
        } catch let error {
            Log.error(message: "Mqtt failed to connect with \(error)")
        }
    }
    
}

extension LightingController: ControllerStateDelagate {
    func didRecieve(_ state: ChannelState, forChannel channel: String, fromController controllerName: String) {
        Log.info(message: "\(controllerName, channel, state)")
    }
}

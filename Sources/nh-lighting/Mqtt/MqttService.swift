//
//  MqttService.swift
//  instrumentation-lighting
//
//  Created by Matt Lloyd on 21/09/2017.
//
//


import Foundation
import PerfectLib
import PerfectMosquitto


protocol ControllerStateDelagate: class {
  func didReceive(_ state: ChannelState, forChannel channel: String, fromController controllerName: String) -> Void
}

// MARK: -
class MqttService {
  
  let serviceName: String
  let host: String
  let port: Int32
  let statusRequestTopic = "nh/status/req"
  let statusReqsponseTopic = "nh/status/res"
  let stateTopic = "nh/li/+/+/state"
  let setTopic = "nh/li/{controller}/{channel}/set"
  let stateTopicPattern = "nh/li/(\\S+)/(I\\d+|\\d{2})/state"
  let mosquitto: Mosquitto
  public var stateDelagate: ControllerStateDelagate?
  
  //MARK: -
  init(clientId: String, host: String, port: Int32) {
    Mosquitto.OpenLibrary()
    serviceName = clientId
    self.host = host
    self.port = port
    
    mosquitto = Mosquitto(id: "nh-lightting")
    mosquitto.OnConnect = OnConnect
    mosquitto.OnDisconnect = OnDisconnect
    mosquitto.OnMessage = OnMessage
  }
  
  deinit {
    do {
      try mosquitto.stop()
    } catch {
      
    }
    mosquitto.OnMessage = { (_) in }
    mosquitto.OnConnect = { (_) in }
    Mosquitto.CloseLibrary()
  }
 
  // MARK: -
  func connect() throws {
    Log.info(message: "Mqtt connecting")
    do {
      try mosquitto.connect(host: host, port: port)
    } catch {
      Log.error(message: "Mqtt failed to connect with \(Mosquitto.Explain(error as! Mosquitto.Exception))")
      throw error
    }
    
    do{
      try mosquitto.start()
    } catch {
      Log.error(message: "Mqtt failed to start with \(Mosquitto.Explain(error as! Mosquitto.Exception))")
      throw error
    }
  }
  
  internal func decodeState(topic: String) -> (controller: String, chanel: String)? {
    let matches = topic.capturedGroups(withRegex: stateTopicPattern)
    
    if matches.isEmpty {
      return nil
    }
    
    return (matches[0], matches[1])
  }
  
  func request(newState state: ChannelState, forOutputChannel channel: OutputChannel, onController controller: Controller) {
    Log.info(message: "Mqtt requesting state: \(state) forOutputChannel: \(channel) onController: \(controller)")
    var topic = setTopic.replacingOccurrences(of: "{controller}", with: controller.name)
    topic = topic.replacingOccurrences(of: "{channel}", with: String(format: "%02d", channel.channel))
    
    var msg = Mosquitto.Message()
    msg.topic = topic
    msg.string = state.rawValue
    
    do {
      try mosquitto.publish(message: msg)
    } catch {
      Log.error(message: "Mqtt request publish failed: \(msg)")
    }
  }
  
  //MARK: - Callbacks
  func OnConnect(_ status: Mosquitto.ConnectionStatus) -> Void {
    if status == .SUCCESS {
      Log.info(message:"Mqtt Connected")
      do {
        var msg = Mosquitto.Message()
        msg.topic = statusReqsponseTopic
        msg.string = "Restart: \(serviceName)"
        try mosquitto.publish(message: msg)
        
        try mosquitto.subscribe(topic: statusRequestTopic)
        try mosquitto.subscribe(topic: stateTopic)
      } catch {
        Log.info(message:"Mqtt subscription failed \(error)")
      }
    }else{
      Log.info(message:"Mqtt connection failed: \(status)")
    }//end if
  }
  
  func OnDisconnect(_ status: Mosquitto.ConnectionStatus) -> Void {
    Log.info(message: "Mqtt disconnect: \(status)")
  }
  
  func OnMessage(_ msg: Mosquitto.Message) -> Void {
    if msg.topic == statusRequestTopic {
      var msg = Mosquitto.Message()
      msg.topic = statusReqsponseTopic
      msg.string = "Running: \(serviceName)"
      do {
        try mosquitto.publish(message: msg)
      } catch {
        
      }
      
    } else if let (controller, channel) = decodeState(topic: msg.topic) {
      if let message = msg.string,
         let state = ChannelState(rawValue: message) {
        guard let stateDelagate = stateDelagate else { Log.error(message: "Did you forget to set the stateDelagate"); return }
        
        stateDelagate.didReceive(state, forChannel: channel, fromController: controller)
      }
    } else {
      Log.info(message: "\(msg.topic, msg.string)")
    }
  }
}

// MARK: - String extension
extension String {
  func capturedGroups(withRegex pattern: String) -> [String] {
    var results = [String]()
    
    var regex: NSRegularExpression
    do {
      regex = try NSRegularExpression(pattern: pattern, options: [])
    } catch {
      return results
    }
    
    let matches = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.count))
    
    guard let match = matches.first else { return results }
    
    let lastRangeIndex = match.numberOfRanges - 1
    guard lastRangeIndex >= 1 else { return results }
    
    for i in 1...lastRangeIndex {
      let capturedGroupIndex = match.range(at: i)
      let matchedString = String(self[Range(capturedGroupIndex, in: self)!])
      results.append(matchedString)
    }
    
    return results
  }
}

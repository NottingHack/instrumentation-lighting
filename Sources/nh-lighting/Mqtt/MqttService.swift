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
  func didRecieve(_ state: ChannelState, forChannel channel: String, fromController controllerName: String) -> Void
}

// MARK: -
class MqttService {
  
  let serviceName: String
  let host: String
  let port: Int32
  let statusRequestTopic = "nh/status/req"
  let statusReqsponseTopic = "nh/status/res"
  let stateTopic = "nh/li/+/+/state"
  let stateTopicPattern = "nh/li/(\\S+)/(I\\d|\\d{2})/state"
  let mosquitto: Mosquitto
  public var stateDelagate: ControllerStateDelagate?
  
  //MARK: -
  init(clientId: String, host: String, port: Int32) {
    Mosquitto.OpenLibrary()
    serviceName = clientId
    self.host = host
    self.port = port
    mosquitto = Mosquitto(id: "nh-lightting")
    
    setupCallbacks()
    
    
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
      Log.error(message: "Mqtt failed to connect with \(Mosquitto.Explain(error as! Mosquitto.Exception))")
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
  
  func setupCallbacks() {
    mosquitto.OnConnect = { (status) in
      if status == .SUCCESS {
        Log.info(message:"Mqtt Connected")
        do {
          var msg = Mosquitto.Message()
          msg.topic = self.statusReqsponseTopic
          msg.string = "Restart: \(self.serviceName)"
          try self.mosquitto.publish(message: msg)
          
          try self.mosquitto.subscribe(topic: self.statusRequestTopic)
          try self.mosquitto.subscribe(topic: self.stateTopic)
        } catch {
          Log.info(message:"Mqtt subscription failed \(error)")
        }
      }else{
        Log.info(message:"Mqtt connection failed: \(status)")
      }//end if
    }
    
    mosquitto.OnDisconnect = { (status) in
      Log.info(message: "Mqtt disconnect: \(status)")
    }
    
    mosquitto.OnMessage = { (msg) in
      if msg.topic == self.statusRequestTopic {
        var msg = Mosquitto.Message()
        msg.topic = self.statusReqsponseTopic
        msg.string = "Running: \(self.serviceName)"
        do {
          try self.mosquitto.publish(message: msg)
        } catch {
          
        }
        
      } else if let (controller, channel) = self.decodeState(topic: msg.topic) {
        if let message = msg.string,
          let state = ChannelState(rawValue: message) {
          guard let stateDelagate = self.stateDelagate else { Log.error(message: "Did you forget to set the stateDelagate"); return }
          
          stateDelagate.didRecieve(state, forChannel: channel, fromController: controller)
        }
      } else {
        Log.info(message: "\(msg.topic, msg.string)")
      }
    }
  }
  
//  func didLoseConnection(error: Error?) {
//    Log.info(message: "connection lost")
//    do {
//      try mosquitto.connect()
//      print("reconnecting")
//    } catch let error {
//      Log.error(message: "Mqtt failed to connect with \(error)")
//      // TODO: try again?
//    }
//  }
//
//  func didCompleteDelivery(token: String) {
//    //        Log.info(message: "didComplete: \(token)")
//  }
//
//  func didReceiveMessage(topic: String, message: String) {
//    if topic == statusRequestTopic {
//      publish(topic: statusReqsponseTopic, withMessage: "Running: \(serviceName)", qos: .atMostOnce)
//    } else if let (controller, channel) = decodeState(topic: topic) {
//      if let state = ChannelState(rawValue: message) {
//        guard let stateDelagate = self.stateDelagate else { Log.error(message: "Did you forget to set the stateDelagate"); return }
//
//        stateDelagate.didRecieve(state, forChannel: channel, fromController: controller)
//      }
//    } else {
//      Log.info(message: "\(topic, message)")
//    }
//  }
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
    
    let matches = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.characters.count))
    
    guard let match = matches.first else { return results }
    
    let lastRangeIndex = match.numberOfRanges - 1
    guard lastRangeIndex >= 1 else { return results }
    
    for i in 1...lastRangeIndex {
      let capturedGroupIndex = match.range(at: i)
      let matchedString = (self as NSString).substring(with: capturedGroupIndex)
      results.append(matchedString)
    }
    
    return results
  }
}

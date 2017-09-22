//
//  MqttService.swift
//  instrumentation-lighting
//
//  Created by Matt Lloyd on 21/09/2017.
//
//


import Foundation
import PerfectLib
import Aphid

protocol ControllerStateDelagate: class {
    func didRecieve(_ state: ChannelState, forChannel channel: String, fromController controllerName: String) -> Void
}

class MqttService: Aphid {
    
    let serviceName: String
    let statusRequestTopic = "nh/status/req"
    let statusReqsponseTopic = "nh/status/res"
    let stateTopic = "nh/li/+/+/state"
    let stateTopicPattern = "nh/li/(lwk-test)/(I\\d|\\d{2})/state"
    
    public var stateDelagate: ControllerStateDelagate?
    
    init(clientId: String, host: String, port: Int32) {
        serviceName = clientId
        
        super.init(clientId: serviceName, host: host, port: port)
        super.delegate = self
    }
    
    internal func decodeState(topic: String) -> (controller: String, chanel: String)? {
        let matches = topic.capturedGroups(withRegex: stateTopicPattern)
        
        if matches.isEmpty {
            return nil
        }
        
        return (matches[0], matches[1])
    }
    
}

extension MqttService: MQTTDelegate {
    func didConnect() {
        Log.info(message:"Mqtt Connected")
        publish(topic: statusReqsponseTopic, withMessage: "Restart: \(serviceName)", qos: .atMostOnce)
        subscribe(topic: [statusRequestTopic, stateTopic], qoss: [.atMostOnce, .atMostOnce])
    }
    
    func didLoseConnection() {
        Log.info(message: "connection lost")
    }
    
    func didCompleteDelivery(token: String) {
        //        Log.info(message: "didComplete: \(token)")
    }
    
    func didReceiveMessage(topic: String, message: String) {
        if topic == statusRequestTopic {
            publish(topic: statusReqsponseTopic, withMessage: "Running: \(serviceName)", qos: .atMostOnce)
        } else if let (controller, channel) = decodeState(topic: topic) {
            if let state = ChannelState(rawValue: message) {
                guard let stateDelagate = self.stateDelagate else { Log.error(message: "Did you forget to set the stateDelagate"); return }
                
                stateDelagate.didRecieve(state, forChannel: channel, fromController: controller)
            }
        } else {
            Log.info(message: "\(topic, message)")
            
        }
    }
    
    func didLoseConnection(error: Error?) {
        Log.info(message: "connection lost error")
    }
}

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
            let capturedGroupIndex = match.rangeAt(i)
            let matchedString = (self as NSString).substring(with: capturedGroupIndex)
            results.append(matchedString)
        }
        
        return results
    }
}

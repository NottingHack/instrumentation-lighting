import Foundation
import Aphid

class MqttClient: Aphid, MQTTDelegate {

    let statusRequestTopic = "nh/status/req"
    let stateTopicPattern = "nh/li/(lwk-test)/(I\\d|\\d{2})/state"

    init(clientId: String) {
        super.init(clientId: clientId)
        super.delegate = self
    }

    func didConnect() {
        print("I connected!")
    }
    func didLoseConnection() {
        print("connection lost")
    }

    func didCompleteDelivery(token: String) {
        // print("didComplete: \(token)")
    }

    func didReceiveMessage(topic: String, message: String) {
        print(topic, message)
        switch topic {
        case "nh/status/req":
            publish(topic: "nh/status/res", withMessage: "Running: \(serviceName)", qos: .atMostOnce)
            

        default:
            print(topic, message)
        }
    }

    func didLoseConnection(error: Error?) {
        print("connection lost error")
    }
    
    func decodeState(topic: String) -> (controller: String, chanel: String)? {
        let matches = topic.capturedGroups(withRegex: stateTopicPattern)
        
        if matches.isEmpty {
            return nil
        }
        
        return (matches[0], matches[1])
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

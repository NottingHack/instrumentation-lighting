//
//  LightingClient.swift
//  instrumentation-lighting
//
//  Created by Matt Lloyd on 23/09/2017.
//
//

import Foundation

struct LightingClient: Hashable {
  var uid: UUID
  var token: String
  var hashValue: Int {
    return token.hashValue
  }
  
  static func ==(lhs: LightingClient, rhs: LightingClient) -> Bool {
    return lhs.uid == rhs.uid
  }
}

// MARK: - 
struct LightStateEvent: Encodable {
  let EventType = "LightState"
  var room: String
  var light: Int
  var state: ChannelState
}

struct RoomDescriptionEvent: Encodable {
  let EventType = "RoomDescription"
  var room: String
  var lights: [Int]
}


struct PatternDescrption: Encodable {
  var patternId: Int
  
  struct LightState: Encodable {
    var room: String
    var light: Int
    var state: ChannelState
  }
  
  var lights: [LightState]
}

// MARK: - 
enum RequestEventType: String, Codable {
  case ConnectRequest
  case LightRequest
  case PatternRequest
}

struct RequestEvent: Decodable {
  let eventType: RequestEventType
  var token: String?
  var room: String?
  var light: Int?
  var state: ChannelState?
  var patternId: Int?
}

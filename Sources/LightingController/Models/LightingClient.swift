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

struct LightStateEvent {
  let EventType = "LightState"
  var room: String
  var light: Int
  var state: ChannelState
}

struct RoomDescriptionEvent {
  let EventType = "RoomDescription"
  var room: String
  var lights: [Int]
}

struct PatternDescriptionEvent {
  let EventType = "PatternDiscription"
  var patternId: Int
  var room: String
  var light: [Int: ChannelState]
}

struct LightRequestEvent {
  let EventType = "LightRequest"
  var room: String
  var light: Int
  var state: ChannelState

}

struct PatternRequestEvent {
  let EventType = "PatternRequest"
  var patternId: Int
}

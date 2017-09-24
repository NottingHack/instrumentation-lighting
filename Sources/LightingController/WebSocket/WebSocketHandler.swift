//
//  WebSocketHandler.swift
//  instrumentation-lighting
//
//  Created by Matt Lloyd on 23/09/2017.
//
//

import PerfectLib
import PerfectHTTP
import PerfectWebSockets

class LightingHandler: WebSocketSessionHandler {
  var client: LightingClient?
  
  let socketProtocol: String? = "lighting"
  
  func handleSession(request req: HTTPRequest, socket: WebSocket) {
    
  }
}

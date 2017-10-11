//
//  WebSocketHandler.swift
//  instrumentation-lighting
//
//  Created by Matt Lloyd on 23/09/2017.
//
//

import Foundation
import PerfectLib
import PerfectHTTP
import PerfectWebSockets

protocol LightingHandlerDelegate {
  func addClientIfNeed(_ handler:WebSocketSessionHandler, request: HTTPRequest, socket:WebSocket, callback:@escaping (_ isSuccess:Bool)->())
  func removeClient(_ socket:WebSocket, callback:@escaping (_ isSuccess:Bool)->())
  func processRequestMessage(_ socket: WebSocket, event: RequestEvent)
}

class LightingHandler: WebSocketSessionHandler {
  var delegate: LightingHandlerDelegate
  var client: LightingClient?
  
  let socketProtocol: String? = "lighting"
  
  init(delegate: LightingHandlerDelegate) {
    self.delegate = delegate
  }
  
  func handleSession(request req: HTTPRequest, socket: WebSocket) {
    
    delegate.addClientIfNeed(self, request: req, socket: socket) { (isSuccess) in
      
    }

    // Read a message from the client as a String.
    // Alternatively we could call `WebSocket.readBytesMessage` to get binary data from the client.
    socket.readStringMessage {
      // This callback is provided:
      //	the received data
      //	the message's op-code
      //	a boolean indicating if the message is complete (as opposed to fragmented)
      string, op, fin in
      
      // The data parameter might be nil here if either a timeout or a network error, such as the client disconnecting, occurred.
      // By default there is no timeout.
      guard let string = string else {
        self.delegate.removeClient(socket, callback: { (isSuccess) in
          socket.close()
        })
        return
      }
      
      // Print some information to the console for informational purposes.
      print("Read msg: \(string) op: \(op) fin: \(fin)")
      

      do {
        let requestEvent = try JSONDecoder().decode(RequestEvent.self, from: string.data(using: .utf8)!)
        self.delegate.processRequestMessage(socket, event: requestEvent)
      } catch {
        print("\(error)")
      }
      
      // Echo the data we received back to the client.
      // Pass true for final. This will usually be the case, but WebSockets has the concept of fragmented messages.
      // For example, if one were streaming a large file such as a video, one would pass false for final.
      // This indicates to the receiver that there is more data to come in subsequent messages but that all the data is part of the same logical message.
      // In such a scenario one would pass true for final only on the last bit of the video.
      socket.sendStringMessage(string: string, final: true) {
        
        // This callback is called once the message has been sent.
        // Recurse to read and echo new message.
        self.handleSession(request: req, socket: socket)
      }
    }
  }
}

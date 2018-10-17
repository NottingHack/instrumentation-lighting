//
//  MySQLService.swift
//  instrumentation-lighting
//
//  Created by Matt Lloyd on 21/09/2017.
//
//

import PerfectLib
import MariaDB
import Foundation

//MARK: -
class MySQLService {
  
  private let host: String
  private let user: String
  private let password: String
  private let database: String
  
  let client = MySQL()
  
  init(host: String, user: String, password: String, database: String) {
    self.host = host
    self.user = user
    self.password = password
    self.database = database
    let _ = client.setOption(.MYSQL_SET_CHARSET_NAME, "utf8")
  }
  
  func loadModels() -> Bool {
    guard client.connect(host: host, user: user, password: password, db: database) else {
      Log.info(message: "Failure connecting to data server \(host)")
      Log.info(message: client.errorMessage())
      return false
    }
    
    lighting = Lighting()
    
    defer {
      client.close()  // defer ensures we close our db connection at the end of this request
    }

    guard loadBuildings(),
          loadFloors(),
          loadRooms(),
          loadLights(),
          loadControllers(),
          loadOutputChannels(),
          loadInputChannels(),
          loadPatterns(),
          loadLightPatterns() else {
      Log.critical(message: "Falied to load Model")
      return false
    }
    Log.info(message: "MySQL loaded model")
    return true
  }
  
  func load(_ select: String, callback: (MySQL.Results.Element) -> ()) -> Bool {
    guard client.query(statement: select) else {
      Log.error(message: client.errorMessage())
      return false
    }
    
    let results = client.storeResults()!
    
    results.forEachRow(callback: callback)

    results.close()
    
    return true
  }
  
  func loadBuildings() -> Bool {
    let select = "SELECT * FROM buildings"

    return load(select) { (row) in
      guard let id = Int(row[0]!),
            let name = row[1] else {
        return
      }
      
      lighting.buildings.append(Building(id: id, name: name))
    }
  }

  func loadFloors() -> Bool {
    let select = "SELECT * FROM floors"

    return load(select) { (row) in
      guard let id = Int(row[0]!),
            let name = row[1],
            let level = Int(row[2]!),
            let buildingId = Int(row[3]!) else {
        return
      }
      
      lighting.floors.append(Floor(id: id, name: name, level: level, buildingId: buildingId))
    }
  }

  func loadRooms() -> Bool {
    let select = "SELECT * FROM rooms"

    return load(select) { (row) in
      guard let id = Int(row[0]!),
            let name = row[1],
            let floorId = Int(row[2]!) else {
        return
      }
      
      lighting.rooms.append(Room(id: id, name: name, floorId: floorId))
    }
  }

  func loadLights() -> Bool {
    let select = "SELECT * FROM lights"

    return load(select) { (row) in
      guard let id = Int(row[0]!),
            let name = row[1],
            let roomId = Int(row[2]!),
            let outputChannelId = Int(row[3]!) else {
        return
      }
      
      lighting.lights.append(Light(id: id, name: name, roomId: roomId, outputChannelId: outputChannelId))
    }
  }

  func loadControllers() -> Bool {
    let select = "SELECT * FROM lighting_controllers"

    return load(select) { (row) in
      guard let id = Int(row[0]!),
            let name = row[1],
            let roomId = Int(row[2]!) else {
        return
      }
      
      lighting.controllers.append(Controller(id: id, name: name, roomId: roomId))
    }
  }

  func loadOutputChannels() -> Bool {
    let select = "SELECT * FROM lighting_output_channels"

    return load(select) { (row) in
      guard let id = Int(row[0]!),
            let channel = Int(row[1]!),
            let controllerId = Int(row[2]!) else {
        return
      }
      
      lighting.outputChannels.append(OutputChannel(id: id, channel: channel, controllerId: controllerId))
    }
  }

  func loadInputChannels() -> Bool {
    let select = "SELECT * FROM lighting_input_channels"

    return load(select) { (row) in
      guard let id = Int(row[0]!),
            let channel = Int(row[1]!),
            let controllerId = Int(row[2]!),
            let statefull = Int(row[4]!) else {
        return
      }
      
      var patternId: Int?
      if let patternString = row[3] {
        patternId = Int(patternString)
      }
    
      lighting.inputChannels.append(InputChannel(id: id, channel: channel, controllerId: controllerId, patternId: patternId, statefull: statefull == 1))
      
      if !inputChannelStateTracking.keys.contains(id) {
        // only add the id tracking if its not allready therey
        // this way we keep state over DB reload
        inputChannelStateTracking[id] = false
      }
      
    }
  }

  func loadPatterns() -> Bool {
    let select = "SELECT * FROM lighting_patterns"

    return load(select) { (row) in
      guard let id = Int(row[0]!),
            let name = row[1] else {
        return
      }
      
      var nextPatternId: Int?
      if let nextPatternString = row[2] {
        nextPatternId = Int(nextPatternString)
      }
      
      var timeout: Int?
      if let timeoutString = row[3] {
        timeout = Int(timeoutString)
      }
      
      lighting.patterns.append(Pattern(id: id, name: name, nextPatternId: nextPatternId, timeout: timeout))
    }
  }
  
  func loadLightPatterns() -> Bool {
    let select = "SELECT * FROM light_lighting_pattern"
    
    return load(select) { (row) in
      guard let lightId = Int(row[1]!),
            let patternId = Int(row[0]!),
            let state = ChannelState(rawValue: row[2]!) else {
        return
      }
      
      lighting.lightPatterns.append(LigthPattern(lightId: lightId, patternId: patternId, state: state))
    }
  }
}

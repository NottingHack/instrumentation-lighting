# WebSocket JSON 

All dictionaries include an `eventType` key identifier

Client's should send one event at a time, however the server may send an array of events to the client  

## Event types
* ConnectRequest  
  Client -> Server  
  Sent upon connection (or reconnection) and include client permission token (TODO: token use is currently unimplemented)

* LightRequest  
  Client -> Server  
  Ask for an individual light to be set to a new state

* PatternRequest  
  Client -> Server  
  Ask for a light pattern to be applied

* LightState  
  Server -> Client  
  The current state of a light

* RoomDescription  
  Server -> Client  
  Describes which lights are in a room

* PatternDescrption  
  Server -> Client  
  Describes light patterns that can be requested

### ConnectRequest 
Sent by the client on (re)connection
```json
{
    "eventType": "ConnectRequest",
    "token": "{token}"
}
```
TODO: `{token}` to be handed out by hms2 laravel for permission checking

### LightRequest
```json
{
    "eventType": "LightRequest",
    "room": "Blue room",
    "light": 1,
    "state": "TOGGLE"
}
```
`state` can be either `ON`, `OFF` or `TOGGLE`(preferred)

### PatternRequest
```json
{
    "eventType": "PatternRequest",
    "patternId": 6
}
```

### LightState
```json
[
    {
        "eventType": "LightState",
        "room": "Blue room",
        "light": 1,
        "state": "ON"
    }
]
```
`state` will be either `ON` or `OFF`

### RoomDescription
```json
{
    "eventType": "RoomDescription",
    "room": "Blue room",
    "lights": [1, 2, 3, 4, 5, 6, 7, 8, 9]
}
```

### PatternDescrption
```json
{
  "eventType": "PatternDescrption",
  "patternId": 6,
  "name": "G4/G5 corridor on",
  "lights": [
    {
      "light": 1,
      "state": "ON",
      "room": "Blue room"
    },
    {
      "light": 2,
      "state": "ON",
      "room": "Blue room"
    },
    {
      "light": 3,
      "state": "ON",
      "room": "Blue room"
    },
    {
      "light": 10,
      "state": "ON",
      "room": "CNC room"
    },
    {
      "light": 11,
      "state": "ON",
      "room": "CNC room"
    },
    {
      "light": 16,
      "state": "ON",
      "room": "CNC room corridor"
    },
    {
      "light": 17,
      "state": "ON",
      "room": "CNC room corridor"
    }
  ]
}
```
`state` can be either `ON`, `OFF` or `TOGGLE`  
Lights not included in the pattern will not be effected


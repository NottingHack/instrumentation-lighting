//
//  main.swift
//  instrumentation-lighting
//
//  Created by Matt Lloyd on 21/09/2017.
//
//

import Foundation
import Signals

let lightingController = LightingController()

Signals.trap(signal: .hup) { signal in
  lightingController.reload()
}

lightingController.start()

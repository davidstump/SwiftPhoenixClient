//
//  Logger.swift
//  SwiftPhoenixClient
//
//  Created by David Stump on 9/21/17.
//

import Foundation

class Logger {
  
  class func debug(message: Any) -> Void {
    #if DEBUG
      print(message)
    #endif
  }

}

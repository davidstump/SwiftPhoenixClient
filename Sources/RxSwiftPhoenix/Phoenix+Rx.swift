//
//  Phoenix+Rx.swift
//  RxSwiftPhoenix
//
//  Created by Daniel Rees on 10/16/19.
//

import Foundation
import RxSwift
import SwiftPhoenix


extension Phoenix: ReactiveCompatible { }

public extension Reactive where Base: Phoenix {
  
  func channel() -> Single<String> {
    return Single.create { [weak base] single in
      single(.success("Rx\(base?.channel() ?? "Channel")"))
      return Disposables.create()
    }
  }
  
  
}

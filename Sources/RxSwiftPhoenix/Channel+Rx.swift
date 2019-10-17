//
//  Channel+Rx.swift
//  RxSwiftPhoenix
//
//  Created by Daniel Rees on 10/16/19.
//

import Foundation
import RxSwift
import SwiftPhoenix

extension Channel: ReactiveCompatible { }

public extension Reactive where Base: Channel {
  
  /// Subscribes on channel events. Disposing of the Subscription will remove
  /// the event callback from the `Channel`.
  ///
  /// There is no error handling, meaning `onError(_)` will never be emitted.
  /// You should inspect the `Message` payload to perform any error handling.
  ///
  /// Example:
  ///
  ///     let channel = socket.channel("topic")
  ///     let disposeBag = DisposeBag()
  ///
  /// // Subscribe to `Message`s for the "event" event
  ///     channel.rx.on("event").subscribe(onNext: { (message) in
  ///       print("do stuff")
  ///     }).addDisposableTo(disposeBag)
  ///
  /// // Clean up the "event" event subscription
  ///     disposeBag.dispose()
  ///
  /// - parameter event: Event to susbcribe to
  /// - return: Observbale that will emit Messages for `event`
  func on(_ event: String) -> Observable<Message> {
    return Observable.create { [weak base] observer in
      let refId = base?.on(event, callback: { observer.onNext($0) })
      return Disposables.create {
        base?.off(event, ref: refId)
      }
    }
  }
  
}

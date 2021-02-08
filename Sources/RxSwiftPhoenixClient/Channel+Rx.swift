// Copyright (c) 2021 David Stump <david@davidstump.net>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import RxSwift
import SwiftPhoenixClient

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

// Copyright (c) 2019 David Stump <david@davidstump.net>
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

class HeartbeatTimer: Equatable {
    let timeInterval: TimeInterval
    let dispatchQueue: DispatchQueue
    let id: String = UUID().uuidString
    init(timeInterval: TimeInterval, dispatchQueue: DispatchQueue) {
        self.timeInterval = timeInterval
        self.dispatchQueue = dispatchQueue
    }
    
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource(flags: [], queue: self.dispatchQueue)
        t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()
    
    var isValid: Bool {
        return state == .resumed
    }
    
    private var eventHandler: (() -> Void)?
    
    private enum State {
        case suspended
        case resumed
    }
    private var state: State = .suspended
    
    
    func startTimerWithEvent(eventHandler: (() -> Void)?) {
        self.eventHandler = eventHandler
        resume()
    }
    
    func stopTimer() {
        timer.setEventHandler {}
        eventHandler = nil
        suspend()
    }
    
    private func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }
    
    private func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
    
    func fire() {
        eventHandler?()
    }
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }
    
    static func == (lhs: HeartbeatTimer, rhs: HeartbeatTimer) -> Bool {
        return lhs.id == rhs.id
    }
}

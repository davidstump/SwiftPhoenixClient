// Copyright (c) 2019 Daniel Rees <daniel.rees18@gmail.com>
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


/// A Timer that calls a given listener based on a configurable time interval.
protocol TimeoutTimable {
    
    /// Listener for when the Timer fires
    var listener: TimeoutTimableListener? { get set }
    
    /// Resets the Timer, clearing the number of tries and stops
    /// any scheduled timeout.
    func reset()
    
    /// Schedules a timeout callback to fire after a calculated timeout duration.
    func scheduleTimeout()
    
}


/// Listener to be informed of events within a Timer. Also provides configuration
protocol TimeoutTimableListener: class {
    
    /// Callback to be called once the timer's interval is reached
    func onTimerTimedOut(_ timer: TimeoutTimable)
    
    /// Provides custom timer interval calculation depending upon how many
    /// tries have been attempted. Accepts `tryCount` as number of tries and is
    /// expecting a return of the next time interval in milliseconds.
    func calculateNextInterval(_ tryCount: Int) -> Int
}


class TimeoutTimer {
    
    /// To be informed of when the Timer fires
    internal weak var listener: TimeoutTimableListener?
    
    /// The underlying Swift Timer which will be scheduled
    fileprivate var underlyingTimer: Timer? = nil
    
    /// The number of times the underlyingTimer hass been set off.
    fileprivate var tries: Int = 0
    
    
    /// Initializes a `TimeoutTimer` which accepts a callback to be called once
    /// the `TimeoutTimer interval is reached and a calculation method which
    /// returns how long the `TimeoutTimer`'s interval should be based on how many
    /// tries the `TimeoutTimer` has attempted.
    init(listener: TimeoutTimableListener) {
        self.listener = listener
    }
    
    
    /// Invalidates any ongoing Timer. Will not clear how many tries have been made
    fileprivate func clearTimer() {
        self.underlyingTimer?.invalidate()
        self.underlyingTimer = nil
    }
    
    /// Called once the Timer is triggered after it's TimeInterval has been reached
    @objc func onTimerTriggered() {
        self.tries += 1
        self.listener?.onTimerTimedOut(self)
    }
    
}

//----------------------------------------------------------------------
// MARK: - TimeoutTimable
//----------------------------------------------------------------------
extension TimeoutTimer: TimeoutTimable {
    func reset() {
        self.tries = 0
        self.clearTimer()
    }
    
    func scheduleTimeout() {
        // Clear any ongoing timer, not resetting the number of tries
        self.clearTimer()
        
        // Get the next calculated interval, in milliseconds. If the listener
        // is nil, then it has been deallocated and we should ignore the call.
        guard let safeListener = self.listener else { return }
        let intervalInMilliseconds = safeListener.calculateNextInterval(self.tries)
        
        // Convert the interval into seconds
        let inervalInSeconds = TimeInterval(intervalInMilliseconds / 1000)
        
        // Start the timer based on the correct iOS version
        if #available(iOS 10.0, *) {
            self.underlyingTimer
                = Timer.scheduledTimer(withTimeInterval: inervalInSeconds,
                                       repeats: false) { (timer) in self.onTimerTriggered() }
        } else {
            self.underlyingTimer
                = Timer.scheduledTimer(timeInterval: inervalInSeconds,
                                       target: self,
                                       selector: #selector(onTimerTriggered),
                                       userInfo: nil,
                                       repeats: false)
        }
    }
}

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

// sourcery: MockableProtocol
protocol TimeoutTimeable {
    
    /// Callback to be informed when the underlying Timer fires
    var callback: Delegated<(), Void> { get set }
    
    /// Provides TimeInterval to use when scheduling the timer
    var timerCalculation: Delegated<Int, TimeInterval>  { get set }
    
    /// Resets the Timer, clearing the number of tries and stops
    /// any scheduled timeout.
    func reset()
    
    /// Schedules a callback to fire after a calculated timeout duration.
    func scheduleTimeout()
}

/// Creates a timer that can perform calculated reties by setting
/// `timerCalculation` , such as exponential backoff.
///
/// ### Example
///
///     let reconnectTimer = TimeoutTimer()
///
///     // Receive a callbcak when the timer is fired
///     reconnectTimer.callback.delegate(to: self) { (_) in
///         print("timer was fired")
///     }
///
///     // Provide timer interval calculation
///     reconnectTimer.timerCalculation.delegate(to: self) { (_, tries) -> TimeInterval in
///         return tries > 2 ? 1000 : [1000, 5000, 10000][tries - 1]
///     }
///
///     reconnectTimer.scheduleTimeout() // fires after 1000ms
///     reconnectTimer.scheduleTimeout() // fires after 5000ms
///     reconnectTimer.reset()
///     reconnectTimer.scheduleTimeout() // fires after 1000ms
class TimeoutTimer: TimeoutTimeable {
    
    /// Callback to be informed when the underlying Timer fires
    var callback = Delegated<(), Void>()
    
    /// Provides TimeInterval to use when scheduling the timer
    var timerCalculation = Delegated<Int, TimeInterval>()
    
    /// The underlying Swift Timer which will be scheduled
    var underlyingTimer: Timer? = nil
    
    /// The number of times the underlyingTimer hass been set off.
    var tries: Int = 0
    
    
    /// Resets the Timer, clearing the number of tries and stops
    /// any scheduled timeout.
    func reset() {
        self.tries = 0
        self.clearTimer()
    }
    
    
    /// Schedules a timeout callback to fire after a calculated timeout duration.
    func scheduleTimeout() {
        // Clear any ongoing timer, not resetting the number of tries
        self.clearTimer()
        
        // Get the next calculated interval, in milliseconds. Do not
        // start the timer if the interval is returned as nil.
        guard let timeInterval
            = self.timerCalculation.call(self.tries + 1) else { return }
        
        // Start the timer based on the correct iOS version
        if #available(iOS 10.0, *) {
            self.underlyingTimer
                = Timer.scheduledTimer(withTimeInterval: timeInterval,
                                       repeats: false) { (timer) in self.onTimerTriggered() }
        } else {
            self.underlyingTimer
                = Timer.scheduledTimer(timeInterval: timeInterval,
                                       target: self,
                                       selector: #selector(onTimerTriggered),
                                       userInfo: nil,
                                       repeats: false)
        }
    }
    
    /// Invalidates any ongoing Timer. Will not clear how many tries have been made
    private func clearTimer() {
        self.underlyingTimer?.invalidate()
        self.underlyingTimer = nil
    }
    
    /// Called once the Timer is triggered after it's TimeInterval has been reached
    @objc func onTimerTriggered() {
        self.tries += 1
        self.callback.call()
    }
}

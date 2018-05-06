//
//  Timer.swift
//  SwiftPhoenixClient
//
//  Created by Daniel Rees on 4/30/18.
//

import Foundation


class PhxTimer {
    
    private let callback: (() -> Void)
    private let timerCalc: ((_ tryCount: Int) -> Int)
    
    private var timer: Timer?
    private var tries: Int
    
    
    /// Creates a timer that accepts a 'timerCalc' function to perform
    /// calculated timeout retries, such as exponential backoff.
    ///
    /// Named "PhxTimer" to avoid a naming conflict with the "Timer" class
    ///
    /// Example:
    ///     let timer = PhxTimer(
    init(callback: @escaping (() -> Void),
         timerCalc: @escaping ((_ tryCount: Int) -> Int)) {
        self.callback = callback
        self.timerCalc = timerCalc
        self.timer = nil
        self.tries = 0
    }
    
    /// Resets the Timer, clearing the number of tries and stops any
    /// ongoing scheduled timeout.
    public func reset() {
        self.tries = 0
        self.clearTimer()
        self.timer?.invalidate()
        self.timer = nil
    }
    
    /// Cancels any previous scheduleTimeout() and schedules another callback
    public func scheduleTimeout() {
        self.clearTimer()
        
        /// Start the Timeout timer.
        let timeout = timerCalc(self.tries)
        let timeoutInSeconds = TimeInterval(timeout / 1000)
        if #available(iOS 10.0, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: timeoutInSeconds,
                                                     repeats: false) { (timer) in
                                                        self.onTimerTriggered()
            }
        } else {
            self.timer = Timer.scheduledTimer(timeInterval: timeoutInSeconds,
                                                     target: self,
                                                     selector: #selector(onTimerTriggered),
                                                     userInfo: nil, repeats: false)
        }
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - Private
    //----------------------------------------------------------------------
    /// Invalidates any ongoing timer, does not reset the tries count.
    private func clearTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    @objc func onTimerTriggered() {
        self.tries += 1
        self.callback()
    }
}

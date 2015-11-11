//
//  Helpers.swift
//  KnobboxDriver
//
//  Created by Sean Robertson on 11/1/15.
//  Copyright © 2015 Prontotype. All rights reserved.
//

import Foundation

func floatValue(value: Int) -> Float {
    return Float(value) / Float(MAX_VALUE)
}

func withDelay(t: Double, callback: (Void) -> Void) {
    let delay = t * Double(NSEC_PER_SEC)
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
    dispatch_after(time, dispatch_get_main_queue(), callback)
}

func withMainThread(callback: () -> Void) {
    dispatch_async(dispatch_get_main_queue(), callback)
}

func debounce_float( delay:NSTimeInterval, queue:dispatch_queue_t, action: ((Float)->()) ) -> (Float)->() {
    var lastFireTime:dispatch_time_t = 0
    let dispatchDelay = Int64(delay * Double(NSEC_PER_SEC))

    return { (value) in
        lastFireTime = dispatch_time(DISPATCH_TIME_NOW,0)
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                dispatchDelay
            ),
            queue) {
                let now = dispatch_time(DISPATCH_TIME_NOW,0)
                let when = dispatch_time(lastFireTime, dispatchDelay)
                if now >= when {
                    action(value)
                }
        }
    }
}

func postNotification(name: String, userInfo: [String: AnyObject] = [:]) {
    NSNotificationCenter.defaultCenter().postNotificationName(name, object: nil, userInfo: userInfo)
}
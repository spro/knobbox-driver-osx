//
//  KnobboxController.swift
//  KnobboxDriver
//
//  Created by Sean Robertson on 11/10/15.
//  Copyright © 2015 Prontotype. All rights reserved.
//

import Cocoa

let MAX_VALUE = 16

var last_mode: Int = 0;
var last_value: Int = 0;

let onKnobboxUpdate: KnobboxUpdateCallback = { (_mode, _value) in
//    print("[onKnobboxUpdate]")

    let mode = Int(_mode)
    let value = Int(_value)

    if mode != last_mode {
        last_mode = mode
        postNotification("didSetMode", userInfo: ["mode": mode])
    }

    if value != last_value {
        last_value = value
        postNotification("didSetValue", userInfo: ["value": value])
    }
}

let onKnobboxConnected: KnobboxVoidCallback = {
    print("[onKnobboxConnected]")
}

let onKnobboxDisconnected: KnobboxVoidCallback = {
    print("[onKnobboxDisconnected]")
}

class KnobboxController: NSObject {
    var mode = 0
    var value: Float = 0
    
    override init() {
        super.init()

        // Device -> Driver notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleSetMode:", name: "didSetMode", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleSetValue:", name: "didSetValue", object: nil)

        // Driver -> Device notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "forwardDeviceNotification:", name: "setMode", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "forwardDeviceNotification:", name: "setValue", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "forwardDeviceNotification:", name: "incMode", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "forwardDeviceNotification:", name: "decMode", object: nil)

    }

    func forwardDeviceNotification(notification: NSNotification) {
        print("[KnobboxController.forwardDeviceNotification] name=\(notification.name)")
        switch notification.name {
        case "incMode":
            knobbox_inc_mode()
        case "decMode":
            knobbox_dec_mode()
        case "setMode":
            let mode = notification.userInfo!["mode"] as! Int
            knobbox_set_mode(Int32(mode))
        case "setValue":
            let value = notification.userInfo!["value"] as! Int
            knobbox_set_value(Int32(value))
        default: break
        }
    }

    func handleSetMode(notification: NSNotification) {
        if let mode = notification.userInfo?["mode"] as? Int {
            withMainThread {
                self.didSetMode(mode)
            }
        }
    }

    func handleSetValue(notification: NSNotification) {
        if let value = notification.userInfo?["value"] as? Int {
            withMainThread {
                self.didSetValue(floatValue(value))
            }
        }
    }

    func didSetMode(mode: Int) {
        print("[KnobboxController.didSetMode] \(mode)")
        self.mode = mode
        wake_screen()
    }

    func didSetValue(value: Float) {
        print("[KnobboxController.didSetValue] \(value)")
        self.value = value
        wake_screen()
        switch self.mode {
            case 3: set_volume(value)
            case 4: set_brightness(value)
            default: print("[didSetValue] Not sure what to do for mode = \(mode)")
        }

    }
}
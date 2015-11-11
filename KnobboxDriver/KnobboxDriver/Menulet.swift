//
//  Menulet.swift
//  KnobboxDriver
//
//  Created by Sean Robertson on 11/4/15.
//  Copyright © 2015 Prontotype. All rights reserved.
//

import Cocoa

@objc protocol MenuletDelegate {
    func menuletMouseDown()
    optional func menuletRightMouseDown()
}

class Menulet: NSView {
    var delegate: MenuletDelegate?
    var mode: Int = 0
    var value: CGFloat = 0.3

    func setup() {
        NSNotificationCenter.defaultCenter().addObserver(self,  selector: "handleSetMode:", name: "didSetMode", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,  selector: "handleSetValue:", name: "didSetValue", object: nil)
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
        self.mode = mode
        self.setNeedsDisplayInRect(self.bounds)
    }

    func didSetValue(value: Float) {
        self.value = CGFloat(value)
        self.setNeedsDisplayInRect(self.bounds)
    }

    override func drawRect(dirtyRect: NSRect) {
        let color = mode_colors[mode] ?? NSColor.whiteColor()

        NSColor(white: 0.5, alpha: 0.25).set()
        let underpath = NSBezierPath()
        underpath.appendBezierPathWithArcWithCenter(NSPoint(x: dirtyRect.width/2, y: dirtyRect.height/2), radius: dirtyRect.width/3, startAngle: 270, endAngle: (0.999 * -1 * 360)+270, clockwise: true)
        underpath.lineWidth = 2
        underpath.stroke()

        color.set()
        let path = NSBezierPath()
        path.appendBezierPathWithArcWithCenter(NSPoint(x: dirtyRect.width/2, y: dirtyRect.height/2), radius: dirtyRect.width/3, startAngle: 270, endAngle: (value * -1 * 360)+270, clockwise: true)
        path.lineWidth = 2
        path.stroke()
    }

    override func mouseDown(theEvent: NSEvent) {
        delegate?.menuletMouseDown()
    }

    override func rightMouseDown(theEvent: NSEvent) {
        delegate?.menuletRightMouseDown?()
    }
}
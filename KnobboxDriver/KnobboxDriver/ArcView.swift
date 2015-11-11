//
//  ArcView.swift
//  KnobboxDriver
//
//  Created by Sean Robertson on 11/3/15.
//  Copyright © 2015 Prontotype. All rights reserved.
//

import Cocoa
import CoreGraphics.CGDisplayConfiguration

let PI: CGFloat = 3.14159265359
let min_eps: CGFloat = PI/15*(1/16)

class ArcView: NSView {
    var mode: Int = 0
    var value: CGFloat = 0.5 // Goal value
    var _value: CGFloat = 0.5 // Animating value

    var timer: NSTimer!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func startAnimating() {
        if self.timer == nil {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1/60, target: self, selector: "step", userInfo: nil, repeats: true)
        }
    }

    func stopAnimating() {
        self.timer?.invalidate()
        self.timer = nil
    }

    override func drawRect(dirtyRect: NSRect) {
        let color = mode_colors[mode] ?? NSColor.whiteColor()
        color.set()
        let path = NSBezierPath()
        path.appendBezierPathWithArcWithCenter(NSPoint(x: dirtyRect.width/2, y: dirtyRect.height/2), radius: dirtyRect.width/3, startAngle: 270, endAngle: (_value * -1 * 360)+270, clockwise: true)
        path.lineWidth = 3
        path.stroke()
    }

    func step() {
        let eps = max(min_eps, PI/15*abs(_value-value))
        if (_value == value) { return }

        if abs(_value - value) < eps*1.1 { _value = value }

        if _value < value {
            _value += eps
        } else if _value > value {
            _value -= eps
        }

        self.setNeedsDisplayInRect(self.bounds)
    }
}

//
//  RoundedRectView.swift
//  KnobboxDriver
//
//  Created by Sean Robertson on 11/3/15.
//  Copyright © 2015 Prontotype. All rights reserved.
//

import Cocoa

class CircleView: NSView {
    var color: NSColor = NSColor.redColor()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func drawRect(dirtyRect: NSRect) {
        self.color.set()
        let path = NSBezierPath(ovalInRect: dirtyRect)
        path.fill()
    }
}

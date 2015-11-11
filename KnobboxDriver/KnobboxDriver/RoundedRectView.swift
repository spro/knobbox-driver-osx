//
//  RoundedRectView.swift
//  KnobboxDriver
//
//  Created by Sean Robertson on 11/3/15.
//  Copyright © 2015 Prontotype. All rights reserved.
//

import Cocoa

class RoundedRectView: NSView {
    var color: NSColor = NSColor(white: 0, alpha: 0.8)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func drawRect(dirtyRect: NSRect) {
        self.color.set()
        let r: CGFloat = 5
        let path = NSBezierPath(roundedRect: dirtyRect, xRadius: r, yRadius: r)
        path.fill()
    }
}

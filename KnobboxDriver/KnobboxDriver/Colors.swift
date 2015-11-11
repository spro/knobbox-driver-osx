//
//  Colors.swift
//  KnobboxDriver
//
//  Created by Sean Robertson on 11/3/15.
//  Copyright © 2015 Prontotype. All rights reserved.
//

import Cocoa

func hueColor(hue: CGFloat) -> NSColor {
    return NSColor(hue: hue/360, saturation: 0.85, brightness: 0.95, alpha: 1)
}

let mode_colors = [
    0: NSColor(white: 1, alpha: 0.2),
    1: hueColor(0),
    2: hueColor(120),
    3: hueColor(230),
    4: NSColor(red: 255/255, green: 210/255, blue: 0, alpha: 1),
    5: hueColor(180),
    6: hueColor(270),
    7: NSColor.whiteColor()
]
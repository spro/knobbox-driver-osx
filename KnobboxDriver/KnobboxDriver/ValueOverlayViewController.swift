//
//  MainViewController.swift
//  KnobboxDriver
//
//  Created by Sean Robertson on 11/1/15.
//  Copyright © 2015 Prontotype. All rights reserved.
//

import Cocoa

let SHOW_MODE_LABEL = false

class ValueOverlayViewController: NSViewController {
    @IBOutlet var modeLabel: NSTextField!
    @IBOutlet var modeIcon: NSImageView!
    @IBOutlet var valueLabel: NSTextField!
    @IBOutlet var backgroundView: RoundedRectView!
    @IBOutlet var arcView: ArcView!

    var mode: Int = 0
    var value: Float = 0

    var fadeOutAnimation: NSViewAnimation!
    var fadeOutTimer: NSTimer!
    var animating = false

    override func awakeFromNib() {
        NSNotificationCenter.defaultCenter().addObserver(self,  selector: "handleSetMode:", name: "didSetMode", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,  selector: "handleSetValue:", name: "didSetValue", object: nil)
        self.view.window!.backgroundColor = NSColor.clearColor()
        self.modeLabel.hidden = !SHOW_MODE_LABEL
        self.showOverlay()
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
        self.showOverlay()
    }

    func didSetValue(value: Float) {
        self.value = value
        self.showOverlay()
    }

    func renderOverlay() {
        self.modeLabel.stringValue = "\(mode)"
        if mode == 0 {
            self.valueLabel.textColor = NSColor(white: 1, alpha: 0.5)
        } else {
            self.valueLabel.textColor = NSColor(white: 1, alpha: 1)
        }
        if let mode_icon = mode_icons[mode] {
            self.modeIcon.image = NSImage(named: mode_icon)
            self.modeIcon.hidden = false
            self.valueLabel.hidden = true
        } else {
            self.modeIcon.hidden = true
            self.valueLabel.hidden = false
        }

        self.arcView.mode = mode
        self.arcView.value = CGFloat(value)

        self.valueLabel.stringValue = "\(value)"
    }

    func showOverlay() {
        self.renderOverlay()

        self.arcView.startAnimating()
        self.arcView.setNeedsDisplayInRect(self.arcView.bounds)

        if self.fadeOutTimer != nil {
            self.fadeOutTimer.invalidate()
            self.fadeOutTimer = nil
        } else if self.animating {
            cancelFadeOut()
        } else {
            self.fadeIn()
            self.view.window?.orderFront(self)
        }
        self.fadeOutTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "fadeOut", userInfo: nil, repeats: false)
    }

    func fadeIn() {
        self.view.window!.level = 999
        self.view.window!.alphaValue = 0
        let fadeOut: [String: AnyObject] = [NSViewAnimationTargetKey: self.view.window!, NSViewAnimationEffectKey: NSViewAnimationFadeInEffect]
        let animations = [fadeOut]
        let animation = NSViewAnimation(viewAnimations: animations)
        animation.duration = 0.05
        animation.startAnimation()
    }

    func cancelFadeOut() {
        print("[ValueOverlayViewController.cancelFadeOut]")
        self.animating = false
        NSAnimationContext.beginGrouping()
        NSAnimationContext.currentContext().duration = 0.01
        self.view.window!.animator().alphaValue = 1
        NSAnimationContext.endGrouping()
    }

    func fadeOut() {
        self.fadeOutTimer?.invalidate()
        self.fadeOutTimer = nil

        withMainThread {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.currentContext().duration = 0.5

            print("[ValueOverlayViewController.fadeOut] Starting")
            self.animating = true
            func fadeOutCompleted() {
                if self.animating {
                    print("[ValueOverlayViewController.fadeOut] Done")
                    self.animating = false
                    self.arcView.stopAnimating()
                    self.view.window!.orderOut(self)
                    self.fadeOutTimer = nil
                }
            }

            NSAnimationContext.currentContext().completionHandler =  fadeOutCompleted
            self.view.window!.animator().alphaValue = 0
            NSAnimationContext.endGrouping()

        }
    }
}

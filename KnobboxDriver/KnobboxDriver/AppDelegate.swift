//
//  AppDelegate.swift
//  KnobboxDriver
//
//  Created by Sean Robertson on 11/1/15.
//  Copyright © 2015 Prontotype. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MenuletDelegate {

    @IBOutlet weak var window: NSWindow!
    var knobboxController: KnobboxController!

    var statusItem: NSStatusItem!
    var menu: NSMenu!
    var mitem: NSMenuItem!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.knobboxController = KnobboxController()
        self.createMenulet()

//        startServer()
//        postFakeValues()

        knobbox_usb_main(onKnobboxConnected, onKnobboxDisconnected, onKnobboxUpdate)
    }

    func createMenulet() {
        let t = NSStatusBar.systemStatusBar().thickness

        let icon = NSImage(named: "statusIconWhite")
        icon?.template = true

        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(t)
        statusItem.image = icon
        let menulet = Menulet()
        statusItem.view = menulet
        menu = NSMenu()
        statusItem.highlightMode = true
        statusItem.enabled = true
        statusItem.menu = menu

        let reset_item = NSMenuItem(title: "Reset", action: "reset", keyEquivalent: "r")
        reset_item.target = self
        statusItem.menu!.addItem(reset_item)

        let quit_item = NSMenuItem(title: "Quit", action: "terminate", keyEquivalent: "q")
        quit_item.target = self
        statusItem.menu!.addItem(quit_item)

        menulet.setup()
        menulet.delegate = self
    }

    func reset() {
        postNotification("setMode", userInfo: ["mode": 0])
        postNotification("setValue", userInfo: ["value": 0])
    }

    func terminate() {
        NSApplication.sharedApplication().terminate(self)
    }

    func menuletMouseDown() {
        self.statusItem.popUpStatusItemMenu(self.statusItem.menu!)
    }

    func postFakeValues() {
        func postValue(value: Float) {
            postNotification("didSetValue", userInfo: ["value": Int(value*Float(MAX_VALUE))])
        }
        postValue(0.5)
        withDelay(0.7) { postValue(0.4) }
        withDelay(1.3) { postValue(0.3) }
        withDelay(2.3) { postValue(0.2) }
        withDelay(3.7) { postValue(0.7) }
    }

}
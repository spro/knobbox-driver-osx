//
//  IOServiceStuff.m
//  KnobboxDriver
//
//  Created by Sean Robertson on 11/2/15.
//  Copyright © 2015 Prontotype. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stdlib.h>
#include <limits.h>

#include <IOKit/graphics/IOGraphicsLib.h>
#include <ApplicationServices/ApplicationServices.h>

const int kMaxDisplays = 16;
const CFStringRef kDisplayBrightness = CFSTR(kIODisplayBrightnessKey);

// Turn off "Automatically adjust brightness" in System Preferences > Display

// Returns the io_service_t corresponding to a CG display ID, or 0 on failure.
// The io_service_t should be released with IOObjectRelease when not needed.
// almost completely from: http://mattdanger.net/2008/12/adjust-mac-os-x-display-brightness-from-the-terminal/
void set_brightness(float new_brightness) {
    CGDirectDisplayID display[kMaxDisplays];
    CGDisplayCount numDisplays;
    CGDisplayErr err;
    err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);

    if (err != CGDisplayNoErr)
        printf("cannot get list of displays (error %d)\n",err);
    else
        printf("Found %d displays\n", numDisplays);

    for (CGDisplayCount i = 0; i < numDisplays; ++i) {
        CGDirectDisplayID dspy = display[i];
        CFDictionaryRef originalMode = CGDisplayCurrentMode(dspy);
        if (originalMode == NULL)
            continue;
        io_service_t service = CGDisplayIOServicePort(dspy);

//            float brightness;
//            err= IODisplayGetFloatParameter(service, kNilOptions, kDisplayBrightness,
//                                            &brightness);
//            if (err != kIOReturnSuccess) {
//                fprintf(stderr,
//                        "failed to get brightness of display 0x%x (error %d)",
//                        (unsigned int)dspy, err);
//                continue;
//            }

        err = IODisplaySetFloatParameter(service, kNilOptions, kDisplayBrightness,
                                         new_brightness);
        if (err != kIOReturnSuccess) {
            fprintf(stderr,
                    "Failed to set brightness of display 0x%x (error %d)",
                    (unsigned int)dspy, err);
            continue;
        }
        break;
    }
    
}

void sleep_screen() {
    io_registry_entry_t regEntry = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
    if (regEntry != MACH_PORT_NULL) {
        IORegistryEntrySetCFProperty(regEntry, CFSTR("IORequestIdle"), kCFBooleanTrue);
        IOObjectRelease(regEntry);
    }
}

void wake_screen() {
    io_registry_entry_t regEntry = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
    if (regEntry != MACH_PORT_NULL) {
        IORegistryEntrySetCFProperty(regEntry, CFSTR("IORequestIdle"), kCFBooleanFalse);
        IOObjectRelease(regEntry);
    }
}

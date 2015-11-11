//
//  USBPrivateDataSample.h
//  KnobboxDriver
//
//  Created by Sean Robertson on 11/3/15.
//  Copyright © 2015 Prontotype. All rights reserved.
//

#ifndef USBPrivateDataSample_h
#define USBPrivateDataSample_h

#endif /* USBPrivateDataSample_h */

typedef void (*KnobboxUpdateCallback)(int mode, int value);
typedef void (*KnobboxVoidCallback)();

int knobbox_usb_main(KnobboxVoidCallback on_knobbox_connect_, KnobboxVoidCallback on_knobbox_disconnect_, KnobboxUpdateCallback on_knobbox_update_);

int knobbox_set_mode(int mode);
int knobbox_set_value(int value);
int knobbox_inc_mode();
int knobbox_dec_mode();

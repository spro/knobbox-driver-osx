//
//  SetVolume.m
//  KnobboxDriver
//
//  Created by Sean Robertson on 11/3/15.
//  Copyright © 2015 Prontotype. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>


void set_channel_volume(UInt32 channel, float new_volume) {
    AudioObjectPropertyAddress getDefaultOutputDevicePropertyAddress = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };

    AudioDeviceID defaultOutputDeviceID;
    UInt32 volumedataSize = sizeof(defaultOutputDeviceID);
    OSStatus result = AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                                 &getDefaultOutputDevicePropertyAddress,
                                                 0, NULL,
                                                 &volumedataSize, &defaultOutputDeviceID);

    if(kAudioHardwareNoError != result)
    {
        // ... handle error ...
    }


    AudioObjectPropertyAddress prop = {
        kAudioDevicePropertyVolumeScalar,
        kAudioDevicePropertyScopeOutput,
        channel
    };

    if(!AudioObjectHasProperty(defaultOutputDeviceID, &prop))
        // error
        NSLog(@"Could not find a default output device");

    uint32_t dataSize = sizeof(new_volume);
    OSStatus result2 = AudioObjectSetPropertyData(defaultOutputDeviceID, &prop, 0, NULL, &dataSize, &new_volume);

    if(kAudioHardwareNoError != result2)
        // error
        NSLog(@"Failed to set property data");

}

void set_volume(float new_volume) {

    set_channel_volume(1, new_volume);
    set_channel_volume(2, new_volume);
}


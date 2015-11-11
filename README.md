# Knobbox driver for OS X

USB device driver for the knobbox (megaknob version). Handles device &rarr; driver state change messages, and can send driver &rarr; device messages to override the current state. Value changes are mapped to system calls per mode, e.g. 3 (blue) changes the volume while 4 (yellow) sets screen brightness. A corresponding overlay shows the current mode and value with an icon and arc.

![knobbox volume overlay](https://github.com/spro/knobbox-driver-osx/blob/master/screenshots/knobbox-driver-volume.png?raw=true)

## TODO:

* User friendly mode mapping
* Individual value per mode

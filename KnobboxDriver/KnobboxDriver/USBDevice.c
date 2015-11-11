#include <CoreFoundation/CoreFoundation.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>

#include "USBDevice.h"

// Change these two constants to match your device's idVendor and idProduct.
// Or, just pass your idVendor and idProduct as command line arguments when running this sample.
#define kMyVendorID			16962
#define kMyProductID		57649

typedef struct KnobboxDevice {
    CFStringRef				deviceName;
    UInt32					locationID;
    io_object_t				notification;

    IOUSBDeviceInterface	**deviceInterface;
    IOUSBInterfaceInterface **interfaceInterface;
    UInt8                   bulkInPipe;

    int mode;
    int value;
} KnobboxDevice;

// TODO: References to KnobboxDevices by location ID?
KnobboxDevice *mainDevice;

static IONotificationPortRef	gNotifyPort;
static io_iterator_t			gAddedIter;
static CFRunLoopRef				gRunLoop;

char						receiveBuffer[1024];

KnobboxUpdateCallback on_knobbox_update;
KnobboxVoidCallback on_knobbox_connect;
KnobboxVoidCallback on_knobbox_disconnect;

void _interruptRecieved(void *refCon, IOReturn result, UInt32 numBytesRead);

void readNextInterrupt(KnobboxDevice *knobboxRef, UInt32 numBytesRead) {
    kern_return_t		kr;
    kr = (*knobboxRef->interfaceInterface)->ReadPipeAsync(knobboxRef->interfaceInterface, knobboxRef->bulkInPipe, receiveBuffer, numBytesRead, (IOAsyncCallback1)_interruptRecieved, (void *) knobboxRef);
    if (kr != kIOReturnSuccess) {
        fprintf(stderr, "Can't read pipe async (%08x)\n", kr);
    }
}

void _interruptRecieved(void *refCon, IOReturn result, UInt32 numBytesRead) {

//    fprintf(stderr, ">> 0x%x 0x%x\n", receiveBuffer[0], receiveBuffer[1]);
    on_knobbox_update(receiveBuffer[0], receiveBuffer[1]);

    KnobboxDevice	*knobboxRef = (KnobboxDevice *) refCon;
    readNextInterrupt(knobboxRef, numBytesRead);
}

//================================================================================================
//
//	DeviceNotification
//
//	This routine will get called whenever any kIOGeneralInterest notification happens.  We are
//	interested in the kIOMessageServiceIsTerminated message so that's what we look for.  Other
//	messages are defined in IOMessage.h.
//
//================================================================================================
void DeviceNotification(void *refCon, io_service_t service, natural_t messageType, void *messageArgument)
{
    kern_return_t	kr;
    KnobboxDevice	*knobboxRef = (KnobboxDevice *) refCon;
    
    if (messageType == kIOMessageServiceIsTerminated) {
        fprintf(stderr, "Device removed.\n");
    
        // Dump our private data to stderr just to see what it looks like.
        fprintf(stderr, "knobboxRef->deviceName: ");
		CFShow(knobboxRef->deviceName);
		fprintf(stderr, "knobboxRef->locationID: 0x%lx.\n\n", (unsigned long) knobboxRef->locationID);
    
        // Free the data we're no longer using now that the device is going away
        CFRelease(knobboxRef->deviceName);
        
        if (knobboxRef->deviceInterface) {
            kr = (*knobboxRef->deviceInterface)->Release(knobboxRef->deviceInterface);
        }
        
        kr = IOObjectRelease(knobboxRef->notification);
        
        free(knobboxRef);

        on_knobbox_disconnect();

        knobbox_wait_for_device();

    }
}

//================================================================================================
//
//	DeviceAdded
//
//	This routine is the callback for our IOServiceAddMatchingNotification.  When we get called
//	we will look at all the devices that were added and we will:
//
//	1.  Create some private data to relate to each device (in this case we use the service's name
//	    and the location ID of the device
//	2.  Submit an IOServiceAddInterestNotification of type kIOGeneralInterest for this device,
//	    using the refCon field to store a pointer to our private data.  When we get called with
//	    this interest notification, we can grab the refCon and access our private data.
//
//================================================================================================
void DeviceAdded(void *refCon, io_iterator_t iterator)
{
    kern_return_t		kr;
    io_service_t		usbRef;
    io_service_t		usbRef2;
    IOCFPlugInInterface	**plugInInterface = NULL;
    IOUSBFindInterfaceRequest interfaceRequest;
    IOUSBInterfaceInterface **interface;
    SInt32				score;
    HRESULT 			res;
    
    while ((usbRef = IOIteratorNext(iterator))) {
        io_name_t		deviceName;
        CFStringRef		deviceNameAsCFString;	
        KnobboxDevice	*knobboxRef = NULL;
        UInt32			locationID;
        
        printf("Device added.\n");

        on_knobbox_connect();
        
        // Add some app-specific information about this device.
        // Create a buffer to hold the data.
        knobboxRef = malloc(sizeof(KnobboxDevice));
        bzero(knobboxRef, sizeof(KnobboxDevice));
        mainDevice = knobboxRef;
        
        // Get the USB device's name.
        kr = IORegistryEntryGetName(usbRef, deviceName);
		if (KERN_SUCCESS != kr) {
            deviceName[0] = '\0';
        }
        
        deviceNameAsCFString = CFStringCreateWithCString(kCFAllocatorDefault, deviceName, 
                                                         kCFStringEncodingASCII);
        
        // Dump our data to stderr just to see what it looks like.
        fprintf(stderr, "deviceName: ");
        CFShow(deviceNameAsCFString);
        
        // Save the device's name to our private data.        
        knobboxRef->deviceName = deviceNameAsCFString;
                                                
        // Now, get the locationID of this device. In order to do this, we need to create an IOusbRefInterface 
        // for our device. This will create the necessary connections between our userland application and the 
        // kernel object for the USB Device.
        kr = IOCreatePlugInInterfaceForService(usbRef, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
                                               &plugInInterface, &score);

        if ((kIOReturnSuccess != kr) || !plugInInterface) {
            fprintf(stderr, "IOCreatePlugInInterfaceForService returned 0x%08x.\n", kr);
            continue;
        }

        // Use the plugin interface to retrieve the device interface.
        res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                 (LPVOID*) &knobboxRef->deviceInterface);
        
        // Now done with the plugin interface.
//        (*plugInInterface)->Release(plugInInterface);

        if (res || knobboxRef->deviceInterface == NULL) {
            fprintf(stderr, "QueryInterface returned %d.\n", (int) res);
            continue;
        }

        // Now that we have the IOUSBDeviceInterface, we can call the routines in IOUSBLib.h.
        // In this case, fetch the locationID. The locationID uniquely identifies the device
        // and will remain the same, even across reboots, so long as the bus topology doesn't change.
//
        kr = (*knobboxRef->deviceInterface)->USBDeviceOpen(knobboxRef->deviceInterface);
        if (KERN_SUCCESS != kr) {
            fprintf(stderr, "Failed to open device.\n");
            continue;
        }


        /////

        interfaceRequest.bInterfaceClass = kIOUSBFindInterfaceDontCare;
        interfaceRequest.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
        interfaceRequest.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
        interfaceRequest.bAlternateSetting = kIOUSBFindInterfaceDontCare;
        (*knobboxRef->deviceInterface)->CreateInterfaceIterator(knobboxRef->deviceInterface,
                                              &interfaceRequest, &iterator);
//        IOIteratorNext(iterator); // skip interface #0
        usbRef2 = IOIteratorNext(iterator);
        IOObjectRelease(iterator);
        kr = IOCreatePlugInInterfaceForService(usbRef2,
                                          kIOUSBInterfaceUserClientTypeID,
                                          kIOCFPlugInInterfaceID, &plugInInterface, &score);
        if (kr != kIOReturnSuccess)
        {
            printf("Could not create interface (error: %08x)\n", kr);
        }

        UInt8                       interfaceClass;
        UInt8                       interfaceSubClass;
        UInt8                       interfaceNumEndpoints;
        int                         pipeRef;

//        while ((usbRef = IOIteratorNext(iterator)))
//        {
//            //Create an intermediate plug-in
//            kr = IOCreatePlugInInterfaceForService(usbRef2,
//                                                   kIOUSBInterfaceUserClientTypeID,
//                                                   kIOCFPlugInInterfaceID,
//                                                   &plugInInterface, &score);
//            //Release the usbRef object after getting the plug-in
////            kr = IOObjectRelease(usbRef2);
//            if ((kr != kIOReturnSuccess) || !plugInInterface)
//            {
//                printf("Unable to create a plug-in (%08x)\n", kr);
//                break;
//            }
//
//            //Now create the device interface for the interface
            res = (*plugInInterface)->QueryInterface(plugInInterface,
                                                        CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
                                                        (LPVOID *) &interface);
//            //No longer need the intermediate plug-in
//            (*plugInInterface)->Release(plugInInterface);

            if (res || !interface)
            {
                printf("CouldnÕt create a device interface for the interface (%08x)\n", (int) res);
                break;
            }
//
//            //Get interface class and subclass
            kr = (*interface)->GetInterfaceClass(interface,
                                                 &interfaceClass);
            kr = (*interface)->GetInterfaceSubClass(interface,
                                                    &interfaceSubClass);

            printf("Interface class %d, subclass %d\n", interfaceClass,
                   interfaceSubClass);
//
            //Now open the interface. This will cause the pipes associated with
            //the endpoints in the interface descriptor to be instantiated
            kr = (*interface)->USBInterfaceOpen(interface);
            if (kr != kIOReturnSuccess)
            {
                printf("Unable to open interface (%08x)\n", kr);
                (void) (*interface)->Release(interface);
                break;
            }
//
            //Get the number of endpoints associated with this interface
            kr = (*interface)->GetNumEndpoints(interface,
                                               &interfaceNumEndpoints);
            if (kr != kIOReturnSuccess)
            {
                printf("Unable to get number of endpoints (%08x)\n", kr);
                (void) (*interface)->USBInterfaceClose(interface);
                (void) (*interface)->Release(interface);
                break;
            }

            printf("Interface has %d endpoints\n", interfaceNumEndpoints);
            //Access each pipe in turn, starting with the pipe at index 1
            //The pipe at index 0 is the default control pipe and should be
            //accessed using (*usbDevice)->DeviceRequest() instead
            for (pipeRef = 1; pipeRef <= interfaceNumEndpoints; pipeRef++)
            {
                IOReturn        kr2;
                UInt8           direction;
                UInt8           number;
                UInt8           transferType;
                UInt16          maxPacketSize;
                UInt8           interval;
                char            *message;

                kr2 = (*interface)->GetPipeProperties(interface,
                                                      pipeRef, &direction,
                                                      &number, &transferType,
                                                      &maxPacketSize, &interval);
                if (kr2 != kIOReturnSuccess)
                    printf("Unable to get properties of pipe %d (%08x)\n",
                           pipeRef, kr2);
                else
                {
                    printf("PipeRef %d: ", pipeRef);
                    switch (direction)
                    {
                        case kUSBOut:
                            message = "out";
                            break;
                        case kUSBIn:
                            message = "in";
                            break;
                        case kUSBNone:
                            message = "none";
                            break;
                        case kUSBAnyDirn:
                            message = "any";
                            break;
                        default:
                            message = "???";
                    }
                    printf("direction %s, ", message);

                    switch (transferType)
                    {
                        case kUSBControl:
                            message = "control";
                            break;
                        case kUSBIsoc:
                            message = "isoc";
                            break;
                        case kUSBBulk:
                            message = "bulk";
                            break;
                        case kUSBInterrupt:
                            message = "interrupt";
                            knobboxRef->interfaceInterface = interface;
                            knobboxRef->bulkInPipe = pipeRef;
                            break;
                        case kUSBAnyType:
                            message = "any";
                            break;
                        default:
                            message = "???";
                    }
                    printf("transfer type %s, maxPacketSize %d\n", message,
                           maxPacketSize);
                }


                UInt32 numBytesRead = 8;
                CFRunLoopSourceRef          runLoopSource;
                (*interface)->CreateInterfaceAsyncEventSource(interface,
                                                              &runLoopSource);
                CFRunLoopAddSource(CFRunLoopGetCurrent(),
                                   runLoopSource, kCFRunLoopDefaultMode);


                readNextInterrupt(knobboxRef, numBytesRead);

                break;


            }
//            deviceNumber ++;
            //For this test, just use first interface, so exit loop
//            break;
//        }



//        IOObjectRelease(usbRef2);
//        (*plugInInterface)->QueryInterface(plugInInterface,
//                                  CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID300),
//                                  (LPVOID)&usbInterface);
//        (*plugInInterface)->Release(plugInInterface);
//
//        kr = (*usbInterface)->USBInterfaceOpen(usbInterface);
//        if (kr != kIOReturnSuccess)
//        {
//            printf("Could not open interface (error: %x)\n", kr);
//        }

        /////

        kr = (*knobboxRef->deviceInterface)->GetLocationID(knobboxRef->deviceInterface, &locationID);
        if (KERN_SUCCESS != kr) {
            fprintf(stderr, "GetLocationID returned 0x%08x.\n", kr);
            continue;
        }
        else {
            fprintf(stderr, "Location ID: 0x%lx\n\n", locationID);
        }

        knobboxRef->locationID = locationID;
        
        // Register for an interest notification of this device being removed. Use a reference to our
        // private data as the refCon which will be passed to the notification callback.
        kr = IOServiceAddInterestNotification(gNotifyPort,						// notifyPort
                                              usbRef,						// service
                                              kIOGeneralInterest,				// interestType
                                              DeviceNotification,				// callback
                                              knobboxRef,					// refCon
                                              &(knobboxRef->notification)	// notification
                                              );

        if (KERN_SUCCESS != kr) {
            printf("IOServiceAddInterestNotification returned 0x%08x.\n", kr);
        }
        
        // Done with this USB device; release the reference added by IOIteratorNext
        kr = IOObjectRelease(usbRef);
    }
}

//================================================================================================
//
//	SignalHandler
//
//	This routine will get called when we interrupt the program (usually with a Ctrl-C from the
//	command line).
//
//================================================================================================
void SignalHandler(int sigraised)
{
    fprintf(stderr, "\nInterrupted.\n");
   
    exit(0);
}

//================================================================================================
//	main
//================================================================================================

static int send_ctrl_msg(IOUSBDeviceInterface** dev, const UInt8 request, const UInt16 value, const UInt16 index) {
    IOUSBDevRequest req;
    req.bmRequestType = USBmakebmRequestType(kUSBIn, kUSBVendor, kUSBDevice);
    req.bRequest = request;
    req.wValue = value;
    req.wIndex = index;
    req.wLength = 0;
    req.pData = 0;
    req.wLenDone = 0;

    IOReturn rc = (*dev)->DeviceRequest(dev, &req);

    if(rc != kIOReturnSuccess) {
        return -1;
    }

    return req.wLenDone;
}

#define USB_MODE_SET 0
#define USB_MODE_INC 1
#define USB_MODE_DEC 2
#define USB_VALUE_SET 3
#define USB_VALUE_INC 4
#define USB_VALUE_DEC 5
#define USB_READ 6
#define USB_RESET 7

#define EJECT_IF_NO_DEVICE if (!mainDevice) { fprintf(stderr, "[ERROR] No knobbox device\n"); return -1; }

int knobbox_set_mode(int mode) {
    EJECT_IF_NO_DEVICE
    return send_ctrl_msg(mainDevice->deviceInterface, USB_MODE_SET, mode, 0);
}

int knobbox_inc_mode() {
    EJECT_IF_NO_DEVICE
    return send_ctrl_msg(mainDevice->deviceInterface, USB_MODE_INC, 0, 0);
}

int knobbox_dec_mode() {
    EJECT_IF_NO_DEVICE
    return send_ctrl_msg(mainDevice->deviceInterface, USB_MODE_DEC, 0, 0);
}

int knobbox_set_value(int value) {
    EJECT_IF_NO_DEVICE
    return send_ctrl_msg(mainDevice->deviceInterface, USB_VALUE_SET, value, 0);
}

int knobbox_wait_for_device() {
    CFMutableDictionaryRef 	matchingDict;
    CFRunLoopSourceRef		runLoopSource;
    CFNumberRef				numberRef;
    kern_return_t			kr;
    long					usbVendor = kMyVendorID;
    long					usbProduct = kMyProductID;
    sig_t					oldHandler;

    // Set up a signal handler so we can clean up when we're interrupted from the command line
    // Otherwise we stay in our run loop forever.
    oldHandler = signal(SIGINT, SignalHandler);
    if (oldHandler == SIG_ERR) {
        fprintf(stderr, "Could not establish new signal handler.");
	}
        
    fprintf(stderr, "Looking for devices matching vendor ID=%ld and product ID=%ld.\n", usbVendor, usbProduct);

    // Set up the matching criteria for the devices we're interested in. The matching criteria needs to follow
    // the same rules as kernel drivers: mainly it needs to follow the USB Common Class Specification, pp. 6-7.
    // See also Technical Q&A QA1076 "Tips on USB driver matching on Mac OS X" 
	// <http://developer.apple.com/qa/qa2001/qa1076.html>.
    // One exception is that you can use the matching dictionary "as is", i.e. without adding any matching 
    // criteria to it and it will match every IOUSBDevice in the system. IOServiceAddMatchingNotification will 
    // consume this dictionary reference, so there is no need to release it later on.
    
    matchingDict = IOServiceMatching(kIOUSBDeviceClassName);	// Interested in instances of class
                                                                // IOUSBDevice and its subclasses
    if (matchingDict == NULL) {
        fprintf(stderr, "IOServiceMatching returned NULL.\n");
//        return -1;
    }
    
    // We are interested in all USB devices (as opposed to USB interfaces).  The Common Class Specification
    // tells us that we need to specify the idVendor, idProduct, and bcdDevice fields, or, if we're not interested
    // in particular bcdDevices, just the idVendor and idProduct.  Note that if we were trying to match an 
    // IOUSBInterface, we would need to set more values in the matching dictionary (e.g. idVendor, idProduct, 
    // bInterfaceNumber and bConfigurationValue.
    
    // Create a CFNumber for the idVendor and set the value in the dictionary
    numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbVendor);
    CFDictionarySetValue(matchingDict, 
                         CFSTR(kUSBVendorID), 
                         numberRef);
    CFRelease(numberRef);
    
    // Create a CFNumber for the idProduct and set the value in the dictionary
    numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbProduct);
    CFDictionarySetValue(matchingDict, 
                         CFSTR(kUSBProductID), 
                         numberRef);
    CFRelease(numberRef);
    numberRef = NULL;

    // Create a notification port and add its run loop event source to our run loop
    // This is how async notifications get set up.
    
    gNotifyPort = IONotificationPortCreate(kIOMasterPortDefault);
    runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
    
    gRunLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(gRunLoop, runLoopSource, kCFRunLoopDefaultMode);
    
    // Now set up a notification to be called when a device is first matched by I/O Kit.
    kr = IOServiceAddMatchingNotification(gNotifyPort,					// notifyPort
                                          kIOFirstMatchNotification,	// notificationType
                                          matchingDict,					// matching
                                          DeviceAdded,					// callback
                                          NULL,							// refCon
                                          &gAddedIter					// notification
                                          );		
                                            
    // Iterate once to get already-present devices and arm the notification    
    DeviceAdded(NULL, gAddedIter);

    return 0;
}

int knobbox_usb_main(KnobboxVoidCallback on_knobbox_connect_, KnobboxVoidCallback on_knobbox_disconnect_, KnobboxUpdateCallback on_knobbox_update_) {
    on_knobbox_update = on_knobbox_update_;
    on_knobbox_connect = on_knobbox_connect_;
    on_knobbox_disconnect = on_knobbox_disconnect_;

    knobbox_wait_for_device();

    // Start the run loop. Now we'll receive notifications.
//    fprintf(stderr, "Starting run loop.\n\n");
//    CFRunLoopRun();

    // We should never get here
//    fprintf(stderr, "Unexpectedly back from CFRunLoopRun()!\n");
    return 0;
}

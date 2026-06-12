import Foundation
import IOKit
import IOKit.usb

struct USBDevice {
    var name: String
    var vendor: String
    var vendorId: Int
    var productId: Int
    var serial: String
    var className: String
}

func scan(className: String) -> [USBDevice] {
    var list: [USBDevice] = []
    let matchingDict = IOServiceMatching(className)
    var iterator: io_iterator_t = 0
    let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
    
    if result == KERN_SUCCESS {
        var entry = IOIteratorNext(iterator)
        while entry != 0 {
            defer { IOObjectRelease(entry) }
            
            var properties: Unmanaged<CFMutableDictionary>?
            let propResult = IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0)
            
            if propResult == kIOReturnSuccess, let dict = properties?.takeRetainedValue() as? [String: Any] {
                let name = dict["USB Product Name"] as? String 
                    ?? dict["productName"] as? String 
                    ?? "Generic Device"
                    
                let vendor = dict["USB Vendor Name"] as? String 
                    ?? dict["vendorName"] as? String 
                    ?? "Unknown Vendor"
                    
                let vendorId = dict["idVendor"] as? Int ?? 0
                let productId = dict["idProduct"] as? Int ?? 0
                let serial = dict["USB Serial Number"] as? String ?? dict["serialNumber"] as? String ?? ""
                
                list.append(USBDevice(
                    name: name,
                    vendor: vendor,
                    vendorId: vendorId,
                    productId: productId,
                    serial: serial,
                    className: className
                ))
            }
            entry = IOIteratorNext(iterator)
        }
        IOObjectRelease(iterator)
    }
    return list
}

print("Scanning for IOUSBDevice...")
let devices = scan(className: "IOUSBDevice")
print("Found \(devices.count) devices.")
for dev in devices {
    print("- \(dev.vendor) \(dev.name) (VID: \(dev.vendorId), PID: \(dev.productId))")
}

print("\nScanning for IOUSBHostDevice...")
let hostDevices = scan(className: "IOUSBHostDevice")
print("Found \(hostDevices.count) host devices.")
for dev in hostDevices {
    print("- \(dev.vendor) \(dev.name) (VID: \(dev.vendorId), PID: \(dev.productId))")
}

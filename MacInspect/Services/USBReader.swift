import Foundation
import IOKit
import IOKit.usb

struct USBDevice: Identifiable, Hashable {
    var id: String {
        return "\(vendorId)-\(productId)-\(serial.replacingOccurrences(of: " ", with: "_"))"
    }
    var name: String
    var vendor: String
    var vendorId: Int
    var productId: Int
    var serial: String
    var speed: String
}

class USBReader {
    /// Queries the IORegistry for both modern (IOUSBHostDevice) and legacy (IOUSBDevice) structures.
    static func getConnectedUSBDevices() -> [USBDevice] {
        var devices = [USBDevice]()
        var uniqueIds = Set<String>()
        
        let classesToScan = ["IOUSBHostDevice", "IOUSBDevice"]
        
        for className in classesToScan {
            let matchingDict = IOServiceMatching(className)
            var iterator: io_iterator_t = 0
            let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
            
            if result == KERN_SUCCESS {
                var entry = IOIteratorNext(iterator)
                while entry != 0 {
                    let currentEntry = entry
                    // Advance iterator immediately so we don't leak on errors
                    entry = IOIteratorNext(iterator)
                    
                    var properties: Unmanaged<CFMutableDictionary>?
                    let propResult = IORegistryEntryCreateCFProperties(currentEntry, &properties, kCFAllocatorDefault, 0)
                    
                    if propResult == kIOReturnSuccess, let dict = properties?.takeRetainedValue() as? [String: Any] {
                        let name = dict["USB Product Name"] as? String 
                            ?? dict["productName"] as? String 
                            ?? "Generic USB Device"
                        
                        let vendor = dict["USB Vendor Name"] as? String 
                            ?? dict["vendorName"] as? String 
                            ?? "Unknown Vendor"
                        
                        let vendorId = dict["idVendor"] as? Int ?? 0
                        let productId = dict["idProduct"] as? Int ?? 0
                        let serial = dict["USB Serial Number"] as? String 
                            ?? dict["serialNumber"] as? String 
                            ?? ""
                        
                        // Translate USB speeds
                        let speedValue = dict["Device Speed"] as? Int 
                            ?? dict["USBSpeed"] as? Int 
                            ?? 0
                        
                        var speedString = "High Speed"
                        if speedValue > 0 {
                            if speedValue >= 3 {
                                speedString = "SuperSpeed"
                            } else if speedValue == 2 {
                                speedString = "High Speed"
                            } else if speedValue == 1 {
                                speedString = "Full Speed"
                            } else if speedValue == 0 {
                                speedString = "Low Speed"
                            }
                        } else if let speedStr = dict["USBSpeed"] as? String {
                            speedString = speedStr
                        }
                        
                        let device = USBDevice(
                            name: name,
                            vendor: vendor,
                            vendorId: vendorId,
                            productId: productId,
                            serial: serial,
                            speed: speedString
                        )
                        
                        if !uniqueIds.contains(device.id) {
                            uniqueIds.insert(device.id)
                            devices.append(device)
                        }
                    }
                    IOObjectRelease(currentEntry)
                }
                IOObjectRelease(iterator)
            }
        }
        return devices
    }
}

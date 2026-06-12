import Foundation
import IOKit
import IOKit.ps
import OSLog

class BatteryReader {
    private static let logger = Logger(subsystem: "com.macinspect.app", category: "BatteryReader")
    
    /// Reads and compiles battery metrics from the macOS kernel.
    static func readBatteryInfo() -> BatteryInfo {
        var info = BatteryInfo()
        
        // 1. Query general power source state via IOPowerSources API
        if let powerSourcesInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let powerSourcesList = IOPSCopyPowerSourcesList(powerSourcesInfo)?.takeRetainedValue() as? [CFTypeRef] {
            
            for source in powerSourcesList {
                if let description = IOPSGetPowerSourceDescription(powerSourcesInfo, source)?.takeUnretainedValue() as? [String: Any] {
                    // Extract capacities
                    let current = description[kIOPSCurrentCapacityKey] as? Int ?? 0
                    let max = description[kIOPSMaxCapacityKey] as? Int ?? 0
                    
                    info.currentCharge = current
                    info.maxCapacity = max
                    
                    logger.log("PowerSource description read: Current=\(current), Max=\(max)")
                }
            }
        }
        
        // 2. Query AppleSmartBattery Registry entry to get hardware-level stats (Cycle Count & Design Capacity)
        let entry = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        if entry != IO_OBJECT_NULL {
            defer { IOObjectRelease(entry) }
            
            var properties: Unmanaged<CFMutableDictionary>?
            let result = IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0)
            
            if result == kIOReturnSuccess, let dict = properties?.takeRetainedValue() as? [String: Any] {
                let cycleCount = dict["CycleCount"] as? Int ?? 0
                let maxCapacity = dict["MaxCapacity"] as? Int ?? 0
                let designCapacity = dict["DesignCapacity"] as? Int ?? 0
                
                info.cycleCount = cycleCount
                
                if maxCapacity > 0 {
                    info.maxCapacity = maxCapacity
                }
                
                if designCapacity > 0 {
                    info.designCapacity = designCapacity
                }
                
                // Determine health retention
                if info.designCapacity > 0 {
                    info.maxCapacityPercent = (Double(info.maxCapacity) / Double(info.designCapacity)) * 100.0
                } else {
                    info.maxCapacityPercent = 0.0
                }
                
                // Estimate health grade
                if info.maxCapacityPercent >= 80.0 {
                    info.health = "Normal"
                } else if info.maxCapacityPercent > 0.0 {
                    info.health = "Service Recommended"
                } else {
                    info.health = "Unknown"
                }
                
                logger.log("AppleSmartBattery Properties read: CycleCount=\(cycleCount), MaxCapacity=\(maxCapacity), DesignCapacity=\(designCapacity), Health=\(info.health)")
            } else {
                logger.error("Failed to query IORegistryEntryCreateCFProperties for AppleSmartBattery.")
            }
        } else {
            // Likely a desktop Mac (Mac mini, Mac Studio, Mac Pro, iMac) which doesn't have a smart battery.
            logger.warning("No AppleSmartBattery service found. Desktop Mac configuration suspected.")
            info.health = "N/A (Desktop Mac)"
            info.cycleCount = 0
            info.maxCapacityPercent = 100.0
            info.maxCapacity = 100
            info.designCapacity = 100
        }
        
        return info
    }
}

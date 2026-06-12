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
                info.cycleCount = cycleCount
                
                // On Apple Silicon, dict["MaxCapacity"] is often reported as a percentage (100)
                // whereas the physical mAh maximum capacity is in "AppleRawMaxCapacity" or "NominalChargeCapacity".
                var max = dict["AppleRawMaxCapacity"] as? Int ?? 0
                if max <= 100 {
                    max = dict["NominalChargeCapacity"] as? Int ?? 0
                }
                if max <= 100 {
                    max = dict["MaxCapacity"] as? Int ?? 0
                }
                
                var design = dict["DesignCapacity"] as? Int ?? 0
                if design <= 100 {
                    design = dict["AppleRawDesignCapacity"] as? Int ?? 0
                }
                
                if max > 0 {
                    info.maxCapacity = max
                }
                if design > 0 {
                    info.designCapacity = design
                }
                
                // Read additional diagnostic values
                if let tempRaw = dict["Temperature"] as? Int {
                    let tempDouble = Double(tempRaw)
                    if tempDouble > 1000.0 {
                        // Kelvin tenths to Celsius
                        info.temperature = (tempDouble / 10.0) - 273.15
                    } else {
                        // Celsius tenths
                        info.temperature = tempDouble / 10.0
                    }
                }
                
                if let voltageRaw = dict["Voltage"] as? Int {
                    info.voltage = Double(voltageRaw) / 1000.0 // millivolts to Volts
                }
                
                info.isCharging = dict["IsCharging"] as? Bool ?? false
                info.isACConnected = dict["ExternalConnected"] as? Bool ?? false
                info.manufacturer = dict["Manufacturer"] as? String ?? "Apple OEM"
                info.deviceName = dict["DeviceName"] as? String ?? "Built-in"
                
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
                
                logger.log("AppleSmartBattery Properties read: CycleCount=\(cycleCount), MaxCapacity=\(info.maxCapacity), DesignCapacity=\(info.designCapacity), Health=\(info.health), Temp=\(info.temperature)C, Volt=\(info.voltage)V")
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

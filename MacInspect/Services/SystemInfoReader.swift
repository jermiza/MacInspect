import Foundation
import IOKit
import OSLog

class SystemInfoReader {
    private static let logger = Logger(subsystem: "com.macinspect.app", category: "SystemInfoReader")
    
    /// Compiles machine technical specifications.
    static func readSystemInfo() -> SystemInfo {
        var info = SystemInfo()
        
        info.model = getMacModel()
        info.chipType = getCpuBrandString()
        info.ram = getPhysicalMemory()
        
        let storage = getStorageInfo()
        info.storageTotal = storage.total
        info.storageFree = storage.free
        
        info.macOSVersion = getMacOSVersion()
        info.serialNumber = getSerialNumber()
        
        logger.log("System Info compiled: Model=\(info.model), Chip=\(info.chipType), RAM=\(info.ram), DiskTotal=\(info.storageTotal), OS=\(info.macOSVersion)")
        
        return info
    }
    
    private static func getMacModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else { return "Mac" }
        
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let modelIdentifier = String(cString: model)
        
        // Add a lookup mapping for friendly Apple Silicon model names
        let modelMapping: [String: String] = [
            // Mac mini
            "Macmini9,1": "Mac mini (M1, 2020)",
            "Mac14,3": "Mac mini (M2, 2023)",
            "Mac14,12": "Mac mini (M2 Pro, 2023)",
            "Mac16,10": "Mac mini (M4, 2024)",
            "Mac16,11": "Mac mini (M4 Pro, 2024)",
            
            // MacBook Air
            "MacBookAir10,1": "MacBook Air (M1, 2020)",
            "Mac14,2": "MacBook Air (M2, 13-inch, 2022)",
            "Mac14,15": "MacBook Air (M2, 15-inch, 2023)",
            "Mac15,3": "MacBook Air (M3, 13-inch, 2024)",
            "Mac15,12": "MacBook Air (M3, 15-inch, 2024)",
            
            // MacBook Pro
            "MacBookPro17,1": "MacBook Pro (13-inch, M1, 2020)",
            "MacBookPro18,3": "MacBook Pro (14-inch, M1 Pro, 2021)",
            "MacBookPro18,4": "MacBook Pro (14-inch, M1 Max, 2021)",
            "MacBookPro18,1": "MacBook Pro (16-inch, M1 Pro, 2021)",
            "MacBookPro18,2": "MacBook Pro (16-inch, M1 Max, 2021)",
            "Mac14,7": "MacBook Pro (13-inch, M2, 2022)",
            "Mac14,9": "MacBook Pro (14-inch, M2 Pro, 2023)",
            "Mac14,5": "MacBook Pro (14-inch, M2 Max, 2023)",
            "Mac14,10": "MacBook Pro (16-inch, M2 Pro, 2023)",
            "Mac14,6": "MacBook Pro (16-inch, M2 Max, 2023)",
            "Mac15,6": "MacBook Pro (14-inch, M3, 2023)",
            "Mac15,8": "MacBook Pro (14-inch, M3 Pro, 2023)",
            "Mac15,10": "MacBook Pro (14-inch, M3 Max, 2023)",
            "Mac15,7": "MacBook Pro (16-inch, M3 Pro, 2023)",
            "Mac15,9": "MacBook Pro (16-inch, M3 Max, 2023)",
            "Mac16,1": "MacBook Pro (14-inch, M4, 2024)",
            "Mac16,6": "MacBook Pro (14-inch, M4 Pro, 2024)",
            "Mac16,8": "MacBook Pro (14-inch, M4 Max, 2024)",
            "Mac16,7": "MacBook Pro (16-inch, M4 Pro, 2024)",
            "Mac16,9": "MacBook Pro (16-inch, M4 Max, 2024)",
            
            // Mac Studio & Pro
            "MacStudio1,1": "Mac Studio (M1 Max/Ultra, 2022)",
            "Mac14,13": "Mac Studio (M2 Max, 2023)",
            "Mac14,14": "Mac Studio (M2 Ultra, 2023)",
            "Mac14,8": "Mac Pro (M2 Ultra, 2023)",
            
            // iMac
            "iMac21,1": "iMac (24-inch, M1, 2-Port, 2021)",
            "iMac21,2": "iMac (24-inch, M1, 4-Port, 2021)",
            "Mac15,4": "iMac (24-inch, M3, 2-Port, 2023)",
            "Mac15,5": "iMac (24-inch, M3, 4-Port, 2023)",
            "Mac16,2": "iMac (24-inch, M4, 2024)"
        ]
        
        if let friendlyName = modelMapping[modelIdentifier] {
            return "\(friendlyName) (\(modelIdentifier))"
        }
        
        return modelIdentifier
    }
    
    private static func getCpuBrandString() -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        if size > 0 {
            var brand = [CChar](repeating: 0, count: size)
            sysctlbyname("machdep.cpu.brand_string", &brand, &size, nil, 0)
            return String(cString: brand).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Alternative fallback for processor architecture details
        var sizeArch = 0
        sysctlbyname("hw.machine", nil, &sizeArch, nil, 0)
        if sizeArch > 0 {
            var machine = [CChar](repeating: 0, count: sizeArch)
            sysctlbyname("hw.machine", &machine, &sizeArch, nil, 0)
            let arch = String(cString: machine)
            if arch == "arm64" {
                return "Apple Silicon (ARM64)"
            }
            return arch
        }
        
        return "Apple Silicon"
    }
    
    private static func getPhysicalMemory() -> String {
        var ramBytes: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        let result = sysctlbyname("hw.memsize", &ramBytes, &size, nil, 0)
        guard result == 0 else { return "Unknown RAM" }
        
        let gb = Double(ramBytes) / (1024.0 * 1024.0 * 1024.0)
        return String(format: "%.0f GB", gb)
    }
    
    private static func getStorageInfo() -> (total: String, free: String) {
        let path = "/"
        do {
            let values = try URL(fileURLWithPath: path).resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            if let total = values.volumeTotalCapacity, let free = values.volumeAvailableCapacity {
                let totalGB = Double(total) / (1024.0 * 1024.0 * 1024.0)
                let freeGB = Double(free) / (1024.0 * 1024.0 * 1024.0)
                return (String(format: "%.0f GB", totalGB), String(format: "%.0f GB", freeGB))
            }
        } catch {
            logger.error("Failed to query filesystem metrics: \(error.localizedDescription)")
        }
        return ("Unknown", "Unknown")
    }
    
    private static func getMacOSVersion() -> String {
        let osInfo = ProcessInfo.processInfo.operatingSystemVersion
        let osName = ProcessInfo.processInfo.operatingSystemVersionString
        
        // Standard output format: 14.2.1
        let versionString = "\(osInfo.majorVersion).\(osInfo.minorVersion).\(osInfo.patchVersion)"
        
        // Detect OS name based on major version
        let marketingName: String
        switch osInfo.majorVersion {
        case 11: marketingName = "Big Sur"
        case 12: marketingName = "Monterey"
        case 13: marketingName = "Ventura"
        case 14: marketingName = "Sonoma"
        case 15: marketingName = "Sequoia"
        default: marketingName = "macOS"
        }
        
        return "\(marketingName) \(versionString)"
    }
    
    private static func getSerialNumber() -> String {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard platformExpert != IO_OBJECT_NULL else {
            logger.error("Could not obtain platform expert service.")
            return "Unknown"
        }
        defer { IOObjectRelease(platformExpert) }
        
        if let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, "IOPlatformSerialNumber" as CFString, kCFAllocatorDefault, 0) {
            let serial = serialNumberAsCFString.takeRetainedValue() as? String ?? "Unknown"
            return serial.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return "Unknown"
    }
}

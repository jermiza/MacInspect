import Foundation

enum TestStatus: String, Codable {
    case pending = "Pending"
    case running = "Running"
    case passed = "Passed"
    case failed = "Failed"
    case skipped = "Skipped"
    
    var colorName: String {
        switch self {
        case .pending: return "gray"
        case .running: return "blue"
        case .passed: return "green"
        case .failed: return "red"
        case .skipped: return "orange"
        }
    }
}

struct TestModule: Identifiable, Codable {
    var id: String
    var name: String
    var iconName: String
    var status: TestStatus = .pending
    var score: Int = 0
    var maxScore: Int = 15
    var details: String = ""
    var isPlaceholder: Bool = false
}

struct BatteryInfo: Codable {
    var health: String = "Unknown"
    var cycleCount: Int = 0
    var maxCapacity: Int = 0
    var designCapacity: Int = 0
    var currentCharge: Int = 0
    var maxCapacityPercent: Double = 0.0
}

struct SystemInfo: Codable {
    var model: String = "MacBook"
    var chipType: String = "Apple Silicon"
    var ram: String = "8 GB"
    var storageTotal: String = "256 GB"
    var storageFree: String = "100 GB"
    var macOSVersion: String = "macOS"
    var serialNumber: String = "Unknown"
}

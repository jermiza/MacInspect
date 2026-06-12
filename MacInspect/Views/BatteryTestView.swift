import SwiftUI

struct BatteryTestView: View {
    @EnvironmentObject var manager: InspectionManager
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Battery Health Diagnostics")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Inspect MacBook power metrics, charging cycles, and retention health.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
            
            Spacer()
            
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Reading battery profiles from device registries...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Diagnostics Layout
                VStack(spacing: 24) {
                    // Visual Circle progress for Battery Max Capacity
                    HStack(spacing: 32) {
                        ZStack {
                            Circle()
                                .stroke(Color.primary.opacity(0.06), lineWidth: 12)
                                .frame(width: 130, height: 130)
                            
                            Circle()
                                .trim(from: 0.0, to: CGFloat(manager.batteryInfo.maxCapacityPercent / 100.0))
                                .stroke(
                                    AngularGradient(
                                        colors: [Color.green, Color.emerald, Color.green],
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 130, height: 130)
                                // Rotate to top
                                .rotationEffect(Angle(degrees: -90))
                            
                            VStack(spacing: 2) {
                                Text(String(format: "%.0f%%", manager.batteryInfo.maxCapacityPercent))
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Capacity")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Summary Stats
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Battery Health:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(manager.batteryInfo.health)
                                    .fontWeight(.bold)
                                    .foregroundColor(manager.batteryInfo.health == "Normal" ? .green : .orange)
                            }
                            
                            HStack {
                                Text("Cycle Count:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(manager.batteryInfo.cycleCount)")
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("Current Charge:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(manager.batteryInfo.currentCharge)%")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(width: 200)
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // Grid details
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        BatteryCard(title: "Maximum Capacity", value: "\(manager.batteryInfo.maxCapacity) mAh", description: "Current maximum charge holding capacity.")
                        BatteryCard(title: "Design Capacity", value: "\(manager.batteryInfo.designCapacity) mAh", description: "Factory brand new capacity design.")
                        BatteryCard(title: "Battery Temp", value: String(format: "%.1f°C", manager.batteryInfo.temperature), description: "Current operating temperature of the cell.")
                        BatteryCard(title: "Voltage", value: String(format: "%.2f V", manager.batteryInfo.voltage), description: "Measured terminal voltage across cells.")
                        BatteryCard(title: "Power Source", value: manager.batteryInfo.isACConnected ? (manager.batteryInfo.isCharging ? "AC (Charging)" : "AC (Power)") : "Battery Power", description: "Current connected power supply.")
                        BatteryCard(title: "Hardware Vendor", value: "\(manager.batteryInfo.manufacturer)", description: "Brand: \(manager.batteryInfo.deviceName)")
                    }
                }
                .padding(28)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .frame(maxWidth: 480)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 16) {
                Button("Recalculate") {
                    withAnimation {
                        isLoading = true
                    }
                    readBattery()
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
                
                Button(action: {
                    let health = manager.batteryInfo.maxCapacityPercent
                    let score: Int
                    if health >= 85.0 {
                        score = 10
                    } else if health >= 75.0 {
                        score = 8
                    } else if health >= 60.0 {
                        score = 6
                    } else {
                        score = 4
                    }
                    
                    let details = "Health Grade: \(manager.batteryInfo.health). Cycles: \(manager.batteryInfo.cycleCount). Capacity ratio: \(Int(health))% (\(manager.batteryInfo.maxCapacity)/\(manager.batteryInfo.designCapacity) mAh)."
                    
                    manager.updateModuleStatus(id: "battery", status: .passed, score: score, details: details)
                    manager.advanceToNext(after: "battery")
                }) {
                    Text("Confirm & Continue")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoading)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            readBattery()
        }
    }
    
    private func readBattery() {
        DispatchQueue.global(qos: .userInitiated).async {
            let info = BatteryReader.readBatteryInfo()
            DispatchQueue.main.async {
                manager.batteryInfo = info
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}

struct BatteryCard: View {
    var title: String
    var value: String
    var description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.02))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}

// Extension to define emerald color cleanly
extension Color {
    static let emerald = Color(red: 16/255, green: 185/255, blue: 129/255)
    static let amber = Color(red: 245/255, green: 158/255, blue: 11/255)
}

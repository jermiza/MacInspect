import SwiftUI

struct SystemInfoView: View {
    @EnvironmentObject var manager: InspectionManager
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("System Specification Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Retrieve detailed model, chipset, and hardware profiling metrics from the kernel.")
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
                    Text("Reading system trees and sysctl properties...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Specs Card
                VStack(spacing: 16) {
                    SpecRow(label: "Mac Model", value: manager.systemInfo.model, icon: "laptopcomputer")
                    SpecRow(label: "Processor / Chip", value: manager.systemInfo.chipType, icon: "cpu")
                    SpecRow(label: "Memory (RAM)", value: manager.systemInfo.ram, icon: "memorychip")
                    SpecRow(label: "Total Disk Storage", value: manager.systemInfo.storageTotal, icon: "internaldrive")
                    SpecRow(label: "Free Disk Space", value: manager.systemInfo.storageFree, icon: "internaldrive.fill")
                    SpecRow(label: "macOS Version", value: manager.systemInfo.macOSVersion, icon: "command.square")
                    
                    Divider()
                    
                    // Serial row with toggle option
                    HStack(spacing: 12) {
                        Image(systemName: "number.square")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Serial Number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            
                            Text(manager.hideSerialNumber ? "••••••••••••" : manager.systemInfo.serialNumber)
                                .font(.body)
                                .foregroundColor(.primary)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                manager.hideSerialNumber.toggle()
                            }
                        }) {
                            Image(systemName: manager.hideSerialNumber ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(manager.hideSerialNumber ? "Show Serial Number" : "Hide Serial Number")
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
                Button(action: {
                    manager.advanceToNext(after: "battery") // Go directly to report
                }) {
                    Text("Proceed to Summary Report")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.blue)
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
            readSystem()
        }
    }
    
    private func readSystem() {
        DispatchQueue.global(qos: .userInitiated).async {
            let info = SystemInfoReader.readSystemInfo()
            DispatchQueue.main.async {
                manager.systemInfo = info
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}

struct SpecRow: View {
    var label: String
    var value: String
    var icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
            }
            Spacer()
        }
    }
}

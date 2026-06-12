import SwiftUI

struct USBTestView: View {
    @EnvironmentObject var manager: InspectionManager
    
    @State private var connectedDevices: [USBDevice] = []
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("USB Port Diagnostics")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Insert an external USB device (flash drive, mouse, keyboard, or adapter) to test port connectivity.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
            
            Spacer()
            
            // Connected devices list card
            VStack(spacing: 16) {
                if connectedDevices.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cable.connector.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                            .opacity(0.6)
                        
                        Text("No External USB Devices Detected")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Plug in any USB accessory to test your computer's USB controller buses and ports in real time.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                        
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .background(Color.primary.opacity(0.02))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.06), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4]))
                    )
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detected USB Hardware (\(connectedDevices.count))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(connectedDevices) { device in
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.1))
                                                .frame(width: 38, height: 38)
                                            Image(systemName: "cable.connector")
                                                .foregroundColor(.blue)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(device.name)
                                                .font(.headline)
                                                .lineLimit(1)
                                            Text("Vendor: \(device.vendor) • Speed: \(device.speed)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("Port Active")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color.primary.opacity(0.03))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .frame(maxHeight: 250)
                    }
                    .padding(20)
                    .background(Color.primary.opacity(0.02))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1.5)
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Evaluation Panel
            VStack(spacing: 12) {
                Text(connectedDevices.isEmpty 
                     ? "Awaiting device connection..." 
                     : "USB port connection verified successfully!")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    Button(action: {
                        stopMonitoring()
                        manager.updateModuleStatus(
                            id: "usb",
                            status: .failed,
                            score: 0,
                            details: "No USB device detected. Controllers or physical ports may be faulty."
                        )
                        manager.advanceToNext(after: "usb")
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("No Response / Failed")
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        stopMonitoring()
                        let count = connectedDevices.count
                        let listNames = connectedDevices.map { $0.name }.joined(separator: ", ")
                        manager.updateModuleStatus(
                            id: "usb",
                            status: .passed,
                            score: 10,
                            details: "Verified ports with \(count) device(s): \(listNames)."
                        )
                        manager.advanceToNext(after: "usb")
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Ports Working")
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(connectedDevices.isEmpty)
                }
            }
            .padding(20)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Button("Skip Test") {
                    stopMonitoring()
                    manager.skipModule(id: "usb")
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
    }
    
    private func startMonitoring() {
        scanDevices()
        
        // Scan every 1.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            scanDevices()
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func scanDevices() {
        let devices = USBReader.getConnectedUSBDevices()
        DispatchQueue.main.async {
            self.connectedDevices = devices.sorted { $0.name < $1.name }
        }
    }
}

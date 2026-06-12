import SwiftUI

struct MicrophoneTestView: View {
    @EnvironmentObject var manager: InspectionManager
    @StateObject private var monitor = MicrophoneMonitor()
    
    @State private var hasPermission = false
    @State private var permissionChecked = false
    @State private var isRecording = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Microphone Test")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Speak into your Mac's microphone to verify sound capture levels and signal patterns.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
            
            Spacer()
            
            if !permissionChecked {
                ProgressView("Checking system audio permissions...")
                    .onAppear {
                        checkPermissions()
                    }
            } else if !hasPermission {
                // Permission Denied View
                VStack(spacing: 16) {
                    Image(systemName: "mic.slash.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text("Microphone Access Required")
                        .font(.headline)
                    
                    Text("Please grant microphone permission in System Settings ➔ Privacy & Security ➔ Microphone to perform this hardware test.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                    
                    Button("Grant Permission") {
                        checkPermissions()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(32)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(12)
                .frame(maxWidth: 400)
            } else {
                // Waveform & Level Meter Display
                VStack(spacing: 24) {
                    // Scrolling Waveform
                    HStack(spacing: 3) {
                        ForEach(0..<monitor.levels.count, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                // Scale bar height based on recorded values
                                .frame(width: 6, height: CGFloat(monitor.levels[index]) * 100 + 4)
                                .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.6), value: monitor.levels[index])
                        }
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(Color.primary.opacity(0.02))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    
                    // Decibel Level Meter
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Input Amplitude Meter")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f%%", monitor.currentLevel * 100))
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.06))
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(monitor.currentLevel))
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .padding(24)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .frame(maxWidth: 480)
            }
            
            Spacer()
            
            // Confirmation Panel
            VStack(spacing: 12) {
                Text("Is the live waveform reacting to your voice and showing normal input levels?")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    Button(action: {
                        monitor.stopMonitoring()
                        manager.updateModuleStatus(
                            id: "microphone",
                            status: .failed,
                            score: 0,
                            details: "No input waveform response observed or mic silent."
                        )
                        manager.advanceToNext(after: "microphone")
                    }) {
                        HStack {
                            Image(systemName: "mic.badge.xmark")
                            Text("Not Working / Dead")
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        monitor.stopMonitoring()
                        manager.updateModuleStatus(
                            id: "microphone",
                            status: .passed,
                            score: 15,
                            details: "Microphone level responsiveness and waveform verified."
                        )
                        manager.advanceToNext(after: "microphone")
                    }) {
                        HStack {
                            Image(systemName: "mic.fill")
                            Text("Working Normally")
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
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
            .disabled(!hasPermission)
            
            Spacer()
            
            HStack {
                Button("Skip Test") {
                    monitor.stopMonitoring()
                    manager.skipModule(id: "microphone")
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            checkPermissions()
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
    }
    
    private func checkPermissions() {
        monitor.checkPermission { granted in
            self.hasPermission = granted
            self.permissionChecked = true
            if granted {
                self.monitor.startMonitoring()
            }
        }
    }
}

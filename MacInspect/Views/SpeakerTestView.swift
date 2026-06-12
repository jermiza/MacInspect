import SwiftUI

struct SpeakerTestView: View {
    @EnvironmentObject var manager: InspectionManager
    @StateObject private var toneGenerator = ToneGenerator()
    
    @State private var activeTestChannel: SpeakerChannel? = nil
    @State private var leftTested = false
    @State private var rightTested = false
    @State private var stereoTested = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Speaker Acoustic Test")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Test each channel separately to check for clarity, distortion, or blown hardware.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
            
            Spacer()
            
            // Audio Testing Controls
            HStack(spacing: 24) {
                // Left Speaker Card
                AcousticChannelCard(
                    title: "Left Speaker",
                    channel: .left,
                    isPlaying: activeTestChannel == .left,
                    isTested: leftTested,
                    systemIcon: "speaker.wave.2.left.fill",
                    action: { runToneTest(for: .left) }
                )
                
                // Stereo Speakers Card
                AcousticChannelCard(
                    title: "Stereo (Both)",
                    channel: .stereo,
                    isPlaying: activeTestChannel == .stereo,
                    isTested: stereoTested,
                    systemIcon: "speaker.wave.3.fill",
                    action: { runToneTest(for: .stereo) }
                )
                
                // Right Speaker Card
                AcousticChannelCard(
                    title: "Right Speaker",
                    channel: .right,
                    isPlaying: activeTestChannel == .right,
                    isTested: rightTested,
                    systemIcon: "speaker.wave.2.right.fill",
                    action: { runToneTest(for: .right) }
                )
            }
            .padding(.horizontal)
            
            // Status Info
            if activeTestChannel != nil {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Playing 440Hz sinus sweep on \(activeTestChannel!.rawValue)...")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .transition(.opacity)
            } else {
                Text("Select a channel to play a 2-second reference tone.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
            
            Spacer()
            
            // Evaluation Panel
            VStack(spacing: 12) {
                Text("Is the audio output clear, undistorted, and playing on correct channels?")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    Button(action: {
                        toneGenerator.stop()
                        manager.updateModuleStatus(
                            id: "speaker",
                            status: .failed,
                            score: 0,
                            details: "Audio distortion, channel imbalance, or silence reported."
                        )
                        manager.advanceToNext(after: "speaker")
                    }) {
                        HStack {
                            Image(systemName: "hand.thumbsdown")
                            Text("Distorted / Muffled")
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        toneGenerator.stop()
                        let score = (leftTested && rightTested && stereoTested) ? 15 : 10
                        manager.updateModuleStatus(
                            id: "speaker",
                            status: .passed,
                            score: score,
                            details: "Clear audio output verified. Left/Right separation tested: \(leftTested && rightTested)."
                        )
                        manager.advanceToNext(after: "speaker")
                    }) {
                        HStack {
                            Image(systemName: "hand.thumbsup")
                            Text("Clear & Balanced")
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
            
            Spacer()
            
            // Actions
            HStack {
                Button("Skip Test") {
                    toneGenerator.stop()
                    manager.skipModule(id: "speaker")
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear {
            toneGenerator.stop()
        }
    }
    
    private func runToneTest(for channel: SpeakerChannel) {
        withAnimation {
            activeTestChannel = channel
        }
        
        toneGenerator.playTone(frequency: 440.0, duration: 2.0, channel: channel)
        
        switch channel {
        case .left: leftTested = true
        case .right: rightTested = true
        case .stereo: stereoTested = true
        }
        
        // Auto reset state after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.activeTestChannel == channel {
                withAnimation {
                    self.activeTestChannel = nil
                }
            }
        }
    }
}

struct AcousticChannelCard: View {
    var title: String
    var channel: SpeakerChannel
    var isPlaying: Bool
    var isTested: Bool
    var systemIcon: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color.blue.opacity(0.15) : Color.primary.opacity(0.04))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: systemIcon)
                        .font(.title2)
                        .foregroundColor(isPlaying ? .blue : (isTested ? .green : .secondary))
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(isPlaying ? "PLAYING" : (isTested ? "Tested" : "Ready"))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isPlaying ? .blue : (isTested ? .green : .secondary))
                }
            }
            .frame(width: 140, height: 130)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(isPlaying ? 0.08 : 0.01), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPlaying ? Color.blue : (isTested ? Color.green.opacity(0.4) : Color.primary.opacity(0.08)), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

import Foundation
import AVFoundation
import OSLog

class MicrophoneMonitor: ObservableObject {
    private let logger = Logger(subsystem: "com.macinspect.app", category: "Microphone")
    private var audioEngine = AVAudioEngine()
    
    @Published var levels: [Float] = Array(repeating: 0.05, count: 40)
    @Published var currentLevel: Float = 0.0
    @Published var isRunning = false
    @Published var isAuthorized = false
    
    func checkPermission(completion: @escaping (Bool) -> Void) {
        let session = AVCaptureDevice.authorizationStatus(for: .audio)
        switch session {
        case .authorized:
            self.isAuthorized = true
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    completion(granted)
                }
            }
        default:
            self.isAuthorized = false
            completion(false)
        }
    }
    
    func startMonitoring() {
        guard !isRunning else { return }
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        guard inputFormat.sampleRate > 0 else {
            logger.error("Invalid input node format sample rate. Audio input might not be available.")
            return
        }
        
        logger.log("Installing tap on audio input node.")
        
        // Remove existing tap first to be safe
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 512, format: inputFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            
            // RMS (Root Mean Square) volume level measurement
            var sum: Float = 0.0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameLength))
            
            // Map to decibel logarithmic scale
            let db = rms > 0 ? 20 * log10(rms) : -60.0
            // Clamp db between -60dB (silence) and 0dB (clipping)
            let clampedDb = max(-60.0, min(0.0, db))
            // Normalize level to a [0.0, 1.0] range
            let normalizedLevel = (clampedDb + 60.0) / 60.0
            
            DispatchQueue.main.async {
                self.currentLevel = normalizedLevel
                
                // Shift levels and append new normalized level
                self.levels.removeFirst()
                // Ensure a visual minimum height for visual feedback
                let displayVal = max(0.05, normalizedLevel)
                self.levels.append(displayVal)
            }
        }
        
        do {
            try audioEngine.start()
            isRunning = true
            logger.log("AVAudioEngine started successfully for microphone monitoring.")
        } catch {
            logger.error("Failed to start audio engine for microphone: \(error.localizedDescription)")
            isRunning = false
        }
    }
    
    func stopMonitoring() {
        guard isRunning else { return }
        logger.log("Removing tap and stopping AVAudioEngine.")
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
        
        // Reset visual outputs
        DispatchQueue.main.async {
            self.currentLevel = 0.0
            self.levels = Array(repeating: 0.05, count: 40)
        }
    }
}

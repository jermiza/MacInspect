import Foundation
import AVFoundation
import OSLog

class ToneGenerator: ObservableObject {
    private let logger = Logger(subsystem: "com.macinspect.app", category: "AudioEngine")
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    
    init() {
        audioEngine.attach(playerNode)
    }
    
    /// Play a generated sine wave on specified speaker channel.
    /// - Parameters:
    ///   - frequency: Frequency of the sine wave (e.g. 440.0 Hz)
    ///   - duration: Playback duration in seconds
    ///   - channel: Left, Right, or Stereo output mapping
    func playTone(frequency: Double, duration: Double, channel: SpeakerChannel) {
        stop()
        
        logger.log("Playing tone: \(frequency)Hz, channel: \(String(describing: channel))")
        
        let sampleRate: Double = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        // Setup stereo format (2 channels)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            logger.error("Failed to initialize stereo audio format.")
            return
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            logger.error("Failed to allocate audio PCM buffer.")
            return
        }
        
        buffer.frameLength = frameCount
        
        let channelsCount = Int(format.channelCount)
        
        for ch in 0..<channelsCount {
            guard let channelData = buffer.floatChannelData?[ch] else { continue }
            
            // Channel assignment logic:
            // Channel 0 = Left Speaker, Channel 1 = Right Speaker
            let shouldPlay: Bool
            switch channel {
            case .left:
                shouldPlay = (ch == 0)
            case .right:
                shouldPlay = (ch == 1)
            case .stereo:
                shouldPlay = true
            }
            
            for frame in 0..<Int(frameCount) {
                if shouldPlay {
                    let time = Double(frame) / sampleRate
                    let val = sin(2.0 * Double.pi * frequency * time)
                    
                    // Apply brief fade-in/out to prevent audio pops
                    let fadeDuration = 0.05
                    let t = time
                    var amplitude = 0.5
                    
                    if t < fadeDuration {
                        amplitude *= (t / fadeDuration)
                    } else if t > duration - fadeDuration {
                        amplitude *= ((duration - t) / fadeDuration)
                    }
                    
                    channelData[frame] = Float(val * amplitude)
                } else {
                    channelData[frame] = 0.0
                }
            }
        }
        
        // Connect nodes to engine
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                logger.error("Could not start AVAudioEngine: \(error.localizedDescription)")
                return
            }
        }
        
        playerNode.play()
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
    
    func stop() {
        if playerNode.isPlaying {
            playerNode.stop()
            logger.log("Audio playback stopped.")
        }
    }
}

enum SpeakerChannel: String, Codable {
    case left = "Left Channel"
    case right = "Right Channel"
    case stereo = "Stereo Channels"
}

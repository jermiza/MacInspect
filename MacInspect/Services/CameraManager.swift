import Foundation
import AVFoundation
import OSLog
import CoreMedia
import CoreVideo

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    override init() {
        super.init()
    }
    

    private let logger = Logger(subsystem: "com.macinspect.app", category: "Camera")
    
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.macinspect.app.sessionQueue")
    
    @Published var isPermissionGranted = false
    @Published var isSessionRunning = false
    @Published var cameraError: String? = nil
    @Published var currentAverageRGB: (r: Double, g: Double, b: Double) = (0.0, 0.0, 0.0)
    
    func checkPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            DispatchQueue.main.async {
                self.isPermissionGranted = true
                completion(true)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isPermissionGranted = granted
                    completion(granted)
                }
            }
        default:
            DispatchQueue.main.async {
                self.isPermissionGranted = false
                completion(false)
            }
        }
    }
    
    func startSession() {
        guard isPermissionGranted else {
            logger.warning("Attempted to start camera session, but camera permission is not granted.")
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.session.isRunning else { return }
            
            self.session.beginConfiguration()
            
            // Clear existing inputs
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            
            // Clear existing outputs
            for output in self.session.outputs {
                self.session.removeOutput(output)
            }
            
            // Resolve default camera device
            guard let videoDevice = AVCaptureDevice.default(for: .video) else {
                DispatchQueue.main.async {
                    self.cameraError = "No camera hardware detected."
                    self.logger.error("No default video capture device available.")
                }
                self.session.commitConfiguration()
                return
            }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                } else {
                    DispatchQueue.main.async {
                        self.cameraError = "Could not connect camera input."
                    }
                    self.logger.error("Unable to add video device input to capture session.")
                }
                
                // Add video data output for processing frames
                let videoDataOutput = AVCaptureVideoDataOutput()
                videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.macinspect.app.videoDataOutputQueue"))
                
                if self.session.canAddOutput(videoDataOutput) {
                    self.session.addOutput(videoDataOutput)
                }
            } catch {
                DispatchQueue.main.async {
                    self.cameraError = "Failed to open camera: \(error.localizedDescription)"
                }
                self.logger.error("Error creating AVCaptureDeviceInput: \(error.localizedDescription)")
            }
            
            self.session.commitConfiguration()
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
                self.logger.log("AVCaptureSession started successfully.")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.session.isRunning else { return }
            
            self.session.stopRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = false
                self.logger.log("AVCaptureSession stopped.")
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else { return }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        var totalR: UInt64 = 0
        var totalG: UInt64 = 0
        var totalB: UInt64 = 0
        
        // Downsample pixels for fast computation (every 16th pixel)
        let step = 16
        var count = 0
        
        for y in stride(from: 0, to: height, by: step) {
            let rowOffset = y * bytesPerRow
            for x in stride(from: 0, to: width, by: step) {
                let pixelOffset = rowOffset + x * 4
                
                // BGRA byte ordering
                let b = buffer[pixelOffset]
                let g = buffer[pixelOffset + 1]
                let r = buffer[pixelOffset + 2]
                
                totalB += UInt64(b)
                totalG += UInt64(g)
                totalR += UInt64(r)
                count += 1
            }
        }
        
        if count > 0 {
            let avgR = Double(totalR) / Double(count) / 255.0
            let avgG = Double(totalG) / Double(count) / 255.0
            let avgB = Double(totalB) / Double(count) / 255.0
            
            DispatchQueue.main.async {
                self.currentAverageRGB = (avgR, avgG, avgB)
            }
        }
    }
}

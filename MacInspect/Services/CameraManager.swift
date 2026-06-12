import Foundation
import AVFoundation
import OSLog

class CameraManager: ObservableObject {
    private let logger = Logger(subsystem: "com.macinspect.app", category: "Camera")
    
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.macinspect.app.sessionQueue")
    
    @Published var isPermissionGranted = false
    @Published var isSessionRunning = false
    @Published var cameraError: String? = nil
    
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
}

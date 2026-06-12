import SwiftUI
import AVFoundation

struct CameraTestView: View {
    @EnvironmentObject var manager: InspectionManager
    @StateObject private var cameraManager = CameraManager()
    
    @State private var hasPermission = false
    @State private var permissionChecked = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Camera Test")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Inspect the FaceTime camera feed for clarity, artifacts, or sensor failure.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
            
            Spacer()
            
            if !permissionChecked {
                ProgressView("Checking camera permissions...")
                    .onAppear {
                        checkPermissions()
                    }
            } else if !hasPermission {
                // Permission Denied View
                VStack(spacing: 16) {
                    Image(systemName: "camera.badge.ellipsis")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text("Camera Access Required")
                        .font(.headline)
                    
                    Text("Please grant camera permission in System Settings ➔ Privacy & Security ➔ Camera to perform this hardware test.")
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
            } else if let error = cameraManager.cameraError {
                // Camera Error View
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.amber)
                    
                    Text("Camera Initialization Failed")
                        .font(.headline)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }
                .padding(32)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(12)
                .frame(maxWidth: 400)
            } else {
                // Live Preview Layer
                VStack {
                    ZStack {
                        CameraPreviewView(cameraManager: cameraManager)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .cornerRadius(12)
                        
                        if !cameraManager.isSessionRunning {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Connecting to camera stream...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: 480, maxHeight: 320)
                    .background(Color.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1.5)
                    )
                }
            }
            
            Spacer()
            
            // Evaluation Panel
            VStack(spacing: 12) {
                Text("Is the camera preview running smoothly and displaying a clear picture?")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    Button(action: {
                        cameraManager.stopSession()
                        manager.updateModuleStatus(
                            id: "camera",
                            status: .failed,
                            score: 0,
                            details: "Camera feed distorted, laggy, or black."
                        )
                        manager.advanceToNext(after: "camera")
                    }) {
                        HStack {
                            Image(systemName: "camera.badge.ellipsis")
                            Text("Distorted / Failed")
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        cameraManager.stopSession()
                        manager.updateModuleStatus(
                            id: "camera",
                            status: .passed,
                            score: 15,
                            details: "Camera feed live preview verified successfully."
                        )
                        manager.advanceToNext(after: "camera")
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Camera Working")
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
            .disabled(!hasPermission || cameraManager.cameraError != nil)
            
            Spacer()
            
            HStack {
                Button("Skip Test") {
                    cameraManager.stopSession()
                    manager.skipModule(id: "camera")
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
            cameraManager.stopSession()
        }
    }
    
    private func checkPermissions() {
        cameraManager.checkPermission { granted in
            self.hasPermission = granted
            self.permissionChecked = true
            if granted {
                self.cameraManager.startSession()
            }
        }
    }
}

// Representable wrapping AVCaptureVideoPreviewLayer
struct CameraPreviewView: NSViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        // Add layer safely
        view.layer?.addSublayer(previewLayer)
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update frame bounds explicitly on layout passes
        if let sublayers = nsView.layer?.sublayers {
            for layer in sublayers {
                if let preview = layer as? AVCaptureVideoPreviewLayer {
                    preview.frame = nsView.bounds
                }
            }
        }
    }
}

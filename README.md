# MacInspect

MacInspect is a native macOS diagnostic utility built in Swift and SwiftUI designed to inspect and grade MacBooks prior to buying or selling them. 

The application runs a sequence of hardware validation tests, profiles battery health, reads core system specifications, and outputs a professional vector PDF report document containing diagnostic validation certificates.

---

## Technical Specifications & Features

- **Language**: Swift 5.0+
- **User Interface**: Native SwiftUI (designed for macOS 13.0+)
- **System Architecture**: Native Apple Silicon support (M1, M2, M3, M4) & Universal Intel binary support.
- **Security**: Sandboxed execution with strict runtime permission declarations.
- **Hardware Integration**:
  - **Keyboard**: Local key intercept monitoring covering standard matrices and flag changes (command, shift, control, fn, arrows).
  - **Display**: Custom borderless window layer overlay to cycles colors for pixel auditing.
  - **Trackpad**: High-precision mouse movement, mouse clicks, secondary clicks, and scroll wheel steps tracker.
  - **Speakers**: Dynamic stereo audio synthesis buffer generation using `AVAudioEngine` for sound panning.
  - **Microphone**: Live tap recording with logarithmic RMS amplitude analysis for decibel meters and vertical waveforms.
  - **Camera**: FaceTime camera previews utilizing `AVCaptureSession` background execution threads.
  - **Battery**: Smart battery registry interrogation (`AppleSmartBattery`) mapping current charge, cycles, design capacity, and health status.
  - **System Specifications**: Unix `sysctl` kernel requests mapping RAM, processor brands, storage drives, and machine model identifiers.

---

## Directory Structure

```text
MacInspect/
├── MacInspect.xcodeproj/
│   └── project.pbxproj            # Xcode Project Configuration
├── MacInspect/
│   ├── MacInspectApp.swift        # SwiftUI Application Entry
│   ├── Info.plist                 # Permissions Usage Strings
│   ├── MacInspect.entitlements    # App Sandbox Permissions
│   ├── Models/
│   │   ├── TestModule.swift       # Test State Models
│   │   └── InspectionManager.swift # Central Inspection Coordinator
│   ├── Services/
│   │   ├── ToneGenerator.swift    # Stereo Sound Synthesizer
│   │   ├── MicrophoneMonitor.swift# Realtime Input Amplitude Monitor
│   │   ├── CameraManager.swift    # Video Session Stream Controller
│   │   ├── BatteryReader.swift    # IOKit MacBook Battery Reader
│   │   └── SystemInfoReader.swift # Unix Sysctl specs parser
│   └── Views/
│       ├── MainView.swift         # Sidebar Navigation Split View
│       ├── WelcomeView.swift      # Welcomer & Onboarding View
│       ├── KeyboardTestView.swift  # Interactive Key Interceptor
│       ├── DisplayTestView.swift   # Fullscreen Solid Color Cycler
│       ├── TrackpadTestView.swift  # Tactile Cursor & Click Tracker
│       ├── SpeakerTestView.swift   # Channel Audio Speaker Router
│       ├── MicrophoneTestView.swift# Waveform Visualizer Screen
│       ├── CameraTestView.swift   # Camera Feed Rendering Frame
│       ├── BatteryTestView.swift  # Cycle & Capacity Dashboards
│       ├── SystemInfoView.swift   # Specifications Summary
│       ├── FinalReportView.swift  # Rating Cards & Vector PDF Compiler
│       └── Placeholders/
│           └── FutureTestsView.swift # Future Diagnostics mocks
└── README.md                      # General Information
```

---

## Compilation and Build Instructions

To compile and execute MacInspect locally, ensure you have macOS 13.0+ and Xcode 14+ installed.

### Using Xcode GUI
1. Open `MacInspect.xcodeproj` in Xcode.
2. Select the `MacInspect` target and choose **My Mac** as the destination.
3. Click the **Run** button (or press `Cmd + R`).

### Using Command Line (Terminal)
To build the project for debugging:
```bash
xcodebuild -project MacInspect.xcodeproj -scheme MacInspect -configuration Debug -destination 'platform=macOS' build
```

To compile a final release bundle:
```bash
xcodebuild -project MacInspect.xcodeproj -scheme MacInspect -configuration Release -destination 'platform=macOS' build
```

---

## Entitlements & Permissions

To capture microphone audio and video feeds, the application requests standard macOS security approvals:
- **FaceTime Camera**: Uses `NSCameraUsageDescription` to describe preview intent and requests runtime permission on demand.
- **Built-in Microphone**: Uses `NSMicrophoneUsageDescription` to capture live waveform inputs.
- **Sandbox Rules**: The `MacInspect.entitlements` file defines:
  - `com.apple.security.device.audio-input`: Allowed
  - `com.apple.security.device.camera`: Allowed
  - `com.apple.security.app-sandbox`: Enabled

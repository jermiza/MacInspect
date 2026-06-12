import SwiftUI

class TrackpadTestState: ObservableObject {
    @Published var hasMoved = false
    @Published var hasClicked = false
    @Published var hasRightClicked = false
    @Published var hasScrolled = false
    
    var isCompleted: Bool {
        return hasMoved && hasClicked && hasRightClicked && hasScrolled
    }
    
    func reset() {
        hasMoved = false
        hasClicked = false
        hasRightClicked = false
        hasScrolled = false
    }
}

struct TrackpadTestView: View {
    @EnvironmentObject var manager: InspectionManager
    @StateObject private var testState = TrackpadTestState()
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Trackpad Test")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Perform each trackpad action inside the grey test area to verify responsiveness.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
            
            // Interaction Status Cards Grid
            HStack(spacing: 16) {
                StatusCard(title: "Cursor Movement", isDone: testState.hasMoved, systemIcon: "cursorarrow")
                StatusCard(title: "Standard Click", isDone: testState.hasClicked, systemIcon: "hand.tap")
                StatusCard(title: "Right Click", isDone: testState.hasRightClicked, systemIcon: "hand.tap.fill")
                StatusCard(title: "Two Finger Scroll", isDone: testState.hasScrolled, systemIcon: "arrow.up.and.down")
            }
            .padding(.horizontal)
            
            // Large Trackpad Mockup (Test Zone)
            VStack {
                Text("TOUCHPAD TEST AREA")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.top, 12)
                
                Spacer()
                
                // Representable layer
                TrackpadTestArea(state: testState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.primary.opacity(0.01)) // must have background to catch hover/clicks
                
                Spacer()
                
                Text("Move cursor, click, right-click, and scroll here")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 2)
            )
            .padding(.horizontal)
            
            Spacer()
            
            // Actions
            HStack(spacing: 16) {
                Button("Skip Test") {
                    manager.skipModule(id: "trackpad")
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    let itemsDone = [testState.hasMoved, testState.hasClicked, testState.hasRightClicked, testState.hasScrolled].filter { $0 }.count
                    let score = Int(Double(itemsDone) / 4.0 * 15.0)
                    let status: TestStatus = (itemsDone == 4) ? .passed : .failed
                    let details = "Completed gestures: \(testState.hasMoved ? "Move " : "")\(testState.hasClicked ? "Click " : "")\(testState.hasRightClicked ? "Right-Click " : "")\(testState.hasScrolled ? "Scroll" : "")."
                    
                    manager.updateModuleStatus(id: "trackpad", status: status, score: score, details: details)
                    manager.advanceToNext(after: "trackpad")
                }) {
                    Text(testState.isCompleted ? "Finish & Continue" : "Submit Partial & Continue")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(testState.isCompleted ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatusCard: View {
    var title: String
    var isDone: Bool
    var systemIcon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemIcon)
                .font(.system(size: 20))
                .foregroundColor(isDone ? .white : .secondary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isDone ? .white : .primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isDone ? Color.green : Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isDone ? Color.green : Color.primary.opacity(0.08), lineWidth: 1)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDone)
    }
}

// Representable wrapping TrackpadMouseTrackingView
struct TrackpadTestArea: NSViewRepresentable {
    @ObservedObject var state: TrackpadTestState
    
    func makeNSView(context: Context) -> TrackpadMouseTrackingView {
        let view = TrackpadMouseTrackingView()
        view.state = state
        return view
    }
    
    func updateNSView(_ nsView: TrackpadMouseTrackingView, context: Context) {
        nsView.state = state
    }
}

class TrackpadMouseTrackingView: NSView {
    var state: TrackpadTestState?
    private var trackingArea: NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let existingArea = trackingArea {
            removeTrackingArea(existingArea)
        }
        
        // Options: mouse moved tracking, active always, visible boundaries
        let options: NSTrackingArea.Options = [
            .mouseMoved,
            .activeAlways,
            .inVisibleRect
        ]
        
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        if state?.hasMoved == false {
            DispatchQueue.main.async {
                self.state?.hasMoved = true
            }
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if state?.hasClicked == false {
            DispatchQueue.main.async {
                self.state?.hasClicked = true
            }
        }
    }
    
    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
        if state?.hasRightClicked == false {
            DispatchQueue.main.async {
                self.state?.hasRightClicked = true
            }
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        if state?.hasScrolled == false {
            // Verify real scroll gesture magnitude
            if abs(event.deltaY) > 0.05 || abs(event.deltaX) > 0.05 {
                DispatchQueue.main.async {
                    self.state?.hasScrolled = true
                }
            }
        }
    }
}
